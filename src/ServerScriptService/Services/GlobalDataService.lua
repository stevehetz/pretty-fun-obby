local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)

-- Create appropriate DataStore prefix based on environment
local StorePrefix = RunService:IsStudio() and "Test_" or "Prod_"
local GlobalFinishersKey = StorePrefix .. "GlobalFinishers"
local GlobalTimesKey = StorePrefix .. "GlobalTimes"
local PlayerInfoKey = StorePrefix .. "PlayerInfo"
local WeeklyResetKey = StorePrefix .. "WeeklyReset"

local CurrentWorldName = WorldsConfig.GetCurrentWorldName()

local GlobalFinishesStore = DataStoreService:GetOrderedDataStore(GlobalFinishersKey .. "_" .. CurrentWorldName)
local GlobalTimesStore = DataStoreService:GetOrderedDataStore(GlobalTimesKey .. "_" .. CurrentWorldName)
local WeeklyResetStore = DataStoreService:GetDataStore(WeeklyResetKey)

local GlobalFinishesMemoryStore = MemoryStoreService:GetSortedMap(GlobalFinishersKey .. "_" .. CurrentWorldName)
local GlobalTimesMemoryStore = MemoryStoreService:GetSortedMap(GlobalTimesKey .. "_" .. CurrentWorldName)
local PlayerInfoMemoryStore = MemoryStoreService:GetHashMap(PlayerInfoKey)

local GetTopFinishersRF = Instance.new("RemoteFunction")
GetTopFinishersRF.Name = "GetTopFinishers"
GetTopFinishersRF.Parent = ReplicatedStorage

local GetTopTimesRF = Instance.new("RemoteFunction")
GetTopTimesRF.Name = "GetTopTimes"
GetTopTimesRF.Parent = ReplicatedStorage

local GetTimeUntilRefreshRF = Instance.new("RemoteFunction")
GetTimeUntilRefreshRF.Name = "GetTimeUntilRefresh"
GetTimeUntilRefreshRF.Parent = ReplicatedStorage

local GetTopTwoTimesPerWorldRF = Instance.new("RemoteFunction")
GetTopTwoTimesPerWorldRF.Name = "GetTopTwoTimesPerWorldRF"
GetTopTwoTimesPerWorldRF.Parent = ReplicatedStorage

local Local = {}
local Shared = {}

-- Function to clear all entries from both global stores
function Local.ClearGlobalStores()
	-- 1. Clear the DataStores
	-- We need to fetch all entries and remove them one by one
	local function clearOrderedDataStore(store, memoryStore, storeName)
		local success, pages = pcall(function()
			return store:GetSortedAsync(false, 100) -- Get up to 100 entries
		end)

		if success then
			local entries = pages:GetCurrentPage()

			local successCount = 0
			local failCount = 0

			for _, entry in ipairs(entries) do
				-- Remove from DataStore
				local dsSuccess = pcall(function()
					store:RemoveAsync(entry.key)
				end)

				-- Remove from MemoryStore
				local msSuccess = pcall(function()
					memoryStore:RemoveAsync(entry.key)
				end)

				if dsSuccess and msSuccess then
					successCount = successCount + 1
				else
					failCount = failCount + 1
				end
			end
		else
			warn("Failed to fetch entries for clearing " .. storeName .. ":", pages)
		end
	end

	-- Get all worlds from WorldsConfig
	local worlds = WorldsConfig.GetAllWorlds()

	-- Clear stores for each world
	for _, worldName in ipairs(worlds) do
		-- Create connections to this world's stores
		local worldTimesStore = DataStoreService:GetOrderedDataStore(GlobalTimesKey .. "_" .. worldName)
		local worldTimesMemoryStore = MemoryStoreService:GetSortedMap(GlobalTimesKey .. "_" .. worldName)

		-- Clear Times Store for this world
		clearOrderedDataStore(worldTimesStore, worldTimesMemoryStore, "GlobalTimesStore_" .. worldName)
	end

	-- Update the last reset timestamp
	local success, err = pcall(function()
		WeeklyResetStore:SetAsync("LastReset", os.time())
	end)

	if not success then
		warn("Failed to update last reset timestamp:", err)
	end

	return true
end

-- Function to check if a weekly reset is needed
function Local.CheckWeeklyReset()
	local success, lastReset = pcall(function()
		return WeeklyResetStore:GetAsync("LastReset")
	end)

	if not success then
		warn("Failed to get last reset timestamp, assuming reset is needed")
		return Local.ClearGlobalStores()
	end

	local currentTime = os.time()
	local oneWeekInSeconds = 7 * 24 * 60 * 60 -- 7 days in seconds

	-- If we've never reset or it's been more than a week since the last reset
	if not lastReset or (currentTime - lastReset) >= oneWeekInSeconds then
		return Local.ClearGlobalStores()
	end
	-- Local.ClearGlobalStores()

	-- Calculate time until next reset
	if lastReset then
		local nextResetTime = lastReset + oneWeekInSeconds
		local timeUntilReset = nextResetTime - currentTime
		local daysUntilReset = math.floor(timeUntilReset / (24 * 60 * 60))
		local hoursUntilReset = math.floor((timeUntilReset % (24 * 60 * 60)) / 3600)

		-- Store the next reset time for the GetTimeUntilRefresh function
		Shared.nextResetTime = nextResetTime
	end

	return false
end

-- Function to manually trigger a reset (can be exposed via admin commands if needed)
function Shared.ManualResetGlobalStores()
	return Local.ClearGlobalStores()
end

Shared.OnStart = function()
	-- Check for weekly reset on server start
	task.spawn(function()
		Local.CheckWeeklyReset()
	end)

	-- Set up a timer to check for weekly reset every hour
	task.spawn(function()
		while true do
			task.wait(3600) -- Check every hour (3600 seconds)
			Local.CheckWeeklyReset()
		end
	end)

	-- Get top finishes from the persistent store and cache them in MemoryStore
	task.spawn(function()
		local success, pages = pcall(function()
			return GlobalFinishesStore:GetSortedAsync(false, 20)
		end)

		if success then
			for _, entry in ipairs(pages:GetCurrentPage()) do
				-- entry.key is userId string, entry.value is their count
				GlobalFinishesMemoryStore:UpdateAsync(entry.key, function()
					return entry.value
				end, 86400) -- Cache for 24 hours

				-- Pre-cache player info for top players
				task.spawn(function()
					Local.FetchAndCachePlayerInfo(entry.key)
				end)
			end
		else
			warn("Leaderboard bootstrap failed: ", pages)
		end
	end)

	-- Get top times from the persistent store and cache them in MemoryStore
	task.spawn(function()
		local success, pages = pcall(function()
			return GlobalTimesStore:GetSortedAsync(false, 20)
		end)

		if success then
			for _, entry in ipairs(pages:GetCurrentPage()) do
				-- entry.key is userId string, entry.value is their time
				GlobalTimesMemoryStore:UpdateAsync(entry.key, function()
					return entry.value
				end, 86400) -- Cache for 24 hours

				-- Pre-cache player info for top players
				task.spawn(function()
					Local.FetchAndCachePlayerInfo(entry.key)
				end)
			end
		else
			warn("Leaderboard bootstrap failed: ", pages)
		end
	end)

	GetTopFinishersRF.OnServerInvoke = function()
		return Shared.GetTopFinishers()
	end

	GetTopTimesRF.OnServerInvoke = function()
		return Shared.GetTopTimes()
	end

	GetTimeUntilRefreshRF.OnServerInvoke = function()
		return Shared.GetTimeUntilRefresh()
	end

	GetTopTwoTimesPerWorldRF.OnServerInvoke = function()
		return Shared.GetTopTwoTimesPerWorld()
	end
end

-- Helper function to fetch and cache player info
function Local.FetchAndCachePlayerInfo(userId)
	userId = tostring(userId)
	local uid = tonumber(userId)

	-- Try to get cached info first
	local ok, cachedInfo = pcall(function()
		return PlayerInfoMemoryStore:GetAsync(userId)
	end)

	-- If we have cached info and it's not expired, return it
	if ok and cachedInfo then
		return cachedInfo
	end

	-- Otherwise fetch fresh info
	local playerInfo = {}

	-- 1) Get username (we'll use this as display name too)
	local successName, username = pcall(Players.GetNameFromUserIdAsync, Players, uid)

	-- 2) Get a thumbnail URL
	local thumbType = Enum.ThumbnailType.AvatarBust
	local thumbSize = Enum.ThumbnailSize.Size48x48
	local successThumb, avatarUrl = pcall(Players.GetUserThumbnailAsync, Players, uid, thumbType, thumbSize)

	playerInfo = {
		username = successName and username or ("Player" .. uid),
		avatarUrl = successThumb and avatarUrl or "",
		lastUpdated = os.time(),
	}

	-- Cache the player info for 24 hours
	pcall(function()
		PlayerInfoMemoryStore:SetAsync(userId, playerInfo, 86400)
	end)

	return playerInfo
end

function Shared.GetTopFinishers()
	local ok, list = pcall(function()
		return GlobalFinishesMemoryStore:GetRangeAsync(Enum.SortDirection.Descending, 20)
	end)
	if not ok then
		return {}
	end

	local out = {}
	for _, entry in ipairs(list) do
		local uid = tonumber(entry.key)
		local finishes = entry.value

		-- Get player info (from cache if available)
		local playerInfo = Local.FetchAndCachePlayerInfo(uid)

		table.insert(out, {
			userId = uid,
			username = playerInfo.username,
			avatarUrl = playerInfo.avatarUrl,
			finishes = finishes,
		})
	end

	-- Ensure results are sorted by finishes in descending order
	table.sort(out, function(a, b)
		return a.finishes > b.finishes
	end)

	-- Assign ranks based on sorted order
	for i, entry in ipairs(out) do
		entry.rank = i
	end

	-- Only return the top 10 entries
	local topEntries = {}
	for i = 1, math.min(10, #out) do
		table.insert(topEntries, out[i])
	end

	return topEntries
end

function Shared.GetTopTimes()
	local ok, list = pcall(function()
		return GlobalTimesMemoryStore:GetRangeAsync(Enum.SortDirection.Ascending, 20)
	end)
	if not ok then
		return {}
	end

	local out = {}
	for _, entry in ipairs(list) do
		local uid = tonumber(entry.key)
		-- Convert stored integer time back to float (seconds)
		local time = entry.value / 1000

		-- Get player info (from cache if available)
		local playerInfo = Local.FetchAndCachePlayerInfo(uid)

		table.insert(out, {
			userId = uid,
			username = playerInfo.username,
			avatarUrl = playerInfo.avatarUrl,
			time = time,
		})
	end

	-- Ensure results are sorted by time in ascending order
	table.sort(out, function(a, b)
		return a.time < b.time
	end)

	-- Assign ranks based on sorted order
	for i, entry in ipairs(out) do
		entry.rank = i
	end

	-- print out all times for debugging
	-- for index, entry in ipairs(out) do
	-- 	print(index .. ":", entry.userId, entry.time)
	-- end

	-- Only return the top 10 entries
	local topEntries = {}
	for i = 1, math.min(10, #out) do
		table.insert(topEntries, out[i])
	end

	return topEntries
end

function Shared.RecordWorldFinish(player, totalFinishes)
	local key = tostring(player.UserId)

	-- 1) Fetch the top 21 entries from the persistent store
	local ok, pages = pcall(function()
		return GlobalFinishesStore:GetSortedAsync(false, 20)
	end)
	if not ok then
		warn("Failed to fetch top entries for prune check:", pages)
		return
	end

	-- print("new finish for " .. key .. ":", totalFinishes)

	-- -- print top 20 finishes for debugging
	-- for index, entry in ipairs(pages:GetCurrentPage()) do
	-- 	print(index .. ":", entry.key, entry.value)
	-- end

	local isPlayerAlreadyOnLeaderboard = false
	for _, entry in ipairs(pages:GetCurrentPage()) do
		if entry.key == key then
			isPlayerAlreadyOnLeaderboard = true
			break
		end
	end

	local entries = pages:GetCurrentPage()
	local countEntries = #entries

	-- 2) Determine the cutoff: if fewer than 20 entries, anyone qualifies
	local cutoff = (countEntries < 20) and -math.huge or entries[20].value

	-- 3) Only set/prune if this player's totalFinishes beats the cutoff
	if totalFinishes > cutoff then
		-- a) Write into the persistent OrderedDataStore
		local sOk, sErr = pcall(function()
			GlobalFinishesStore:SetAsync(key, totalFinishes)
		end)
		if not sOk then
			warn("Failed to set global finish for", key, sErr)
		end

		-- First remove the key from MemoryStore to clear any cached value
		pcall(function()
			GlobalFinishesMemoryStore:RemoveAsync(key)
		end)

		-- Then add the new value
		GlobalFinishesMemoryStore:UpdateAsync(key, function()
			return totalFinishes
		end, 86400) -- Cache for 24 hours

		-- b) Prune the now 21st entry if it exists from the persistent store and MemoryStore
		if not isPlayerAlreadyOnLeaderboard and countEntries >= 20 and entries[20] then
			pcall(function()
				GlobalFinishesStore:RemoveAsync(entries[20].key)
			end)

			GlobalFinishesMemoryStore:RemoveAsync(entries[20].key)
		end

		-- 5) Pre-cache this player's info since they're on the leaderboard now
		task.spawn(function()
			Local.FetchAndCachePlayerInfo(player.UserId)
		end)
	end
end

function Shared.RecordTimeFinish(player, time)
	local key = tostring(player.UserId)

	-- Convert floating-point time to integer (milliseconds)
	-- This prevents the "double is not allowed in data stores" error
	local timeInteger = math.floor(time * 1000)

	-- 1) Fetch the top 21 entries from the persistent store
	local ok, pages = pcall(function()
		return GlobalTimesStore:GetSortedAsync(true, 20)
	end)
	if not ok then
		warn("Failed to fetch top entries for prune check:", pages)
		return
	end

	-- print("new time for " .. key .. ":", timeInteger / 1000)

	-- -- print top 21 times for debugging
	-- for index, entry in ipairs(pages:GetCurrentPage()) do
	-- 	print(index .. ":", entry.key, entry.value / 1000)
	-- end

	local isPlayerAlreadyOnLeaderboard = false
	for _, entry in ipairs(pages:GetCurrentPage()) do
		if entry.key == key then
			isPlayerAlreadyOnLeaderboard = true
			break
		end
	end

	local entries = pages:GetCurrentPage()
	local countEntries = #entries

	-- Convert any existing entries from integer back to float for comparison
	local cutoffValue = (countEntries < 20) and math.huge or (entries[20].value / 1000)

	-- 3) Only set/prune if this player's time beats the cutoff
	if time < cutoffValue then
		-- a) Write into the persistent OrderedDataStore (as integer)
		local sOk, sErr = pcall(function()
			GlobalTimesStore:SetAsync(key, timeInteger)
		end)
		if not sOk then
			warn("Failed to set global time for", key, sErr)
		end

		-- b) Mirror into MemoryStore cache (also as integer)
		-- First remove the key from MemoryStore to clear any cached value
		pcall(function()
			GlobalTimesMemoryStore:RemoveAsync(key)
		end)

		-- Then add the new value
		GlobalTimesMemoryStore:UpdateAsync(key, function()
			return timeInteger
		end, 86400) -- Cache for 24 hours

		-- c) Pruning the now 21st entry if it exists from the persistent store and MemoryStore
		if not isPlayerAlreadyOnLeaderboard and countEntries >= 20 and entries[20] then
			pcall(function()
				GlobalTimesStore:RemoveAsync(entries[20].key)
			end)

			GlobalTimesMemoryStore:RemoveAsync(entries[20].key)
		end

		-- 5) Pre-cache this player's info since they're on the leaderboard now
		task.spawn(function()
			Local.FetchAndCachePlayerInfo(player.UserId)
		end)
	end
end

-- Function to get the time until the next leaderboard refresh
function Shared.GetTimeUntilRefresh()
	-- If we don't have a next reset time stored, try to calculate it
	if not Shared.nextResetTime then
		local success, lastReset = pcall(function()
			return WeeklyResetStore:GetAsync("LastReset")
		end)

		if success and lastReset then
			local oneWeekInSeconds = 7 * 24 * 60 * 60 -- 7 days in seconds
			Shared.nextResetTime = lastReset + oneWeekInSeconds
		else
			-- If we can't get the last reset time, return nil
			return nil
		end
	end

	local currentTime = os.time()
	local timeUntilReset = Shared.nextResetTime - currentTime

	-- If the time is negative, a reset is due but hasn't happened yet
	if timeUntilReset < 0 then
		return 0
	end

	-- Return the time remaining in seconds
	return timeUntilReset
end

-- Function to get the top two times for each world
function Shared.GetTopTwoTimesPerWorld()
	local worlds = WorldsConfig.GetAllWorlds()
	local results = {}

	for _, worldName in ipairs(worlds) do
		-- Create a temporary connection to this world's GlobalTimesMemoryStore
		local worldTimesMemoryStore = MemoryStoreService:GetSortedMap(GlobalTimesKey .. "_" .. worldName)

		-- Get the top 20 times from this world's memory store (like GetTopTimes does)
		local ok, list = pcall(function()
			return worldTimesMemoryStore:GetRangeAsync(Enum.SortDirection.Ascending, 20)
		end)

		if ok and list then
			local worldTimes = {}

			for _, entry in ipairs(list) do
				local uid = tonumber(entry.key)
				-- Convert stored integer time back to float (seconds)
				local time = entry.value / 1000

				-- Get player info (from cache if available)
				local playerInfo = Local.FetchAndCachePlayerInfo(uid)

				table.insert(worldTimes, {
					userId = uid,
					username = playerInfo.username,
					avatarUrl = playerInfo.avatarUrl,
					time = time,
				})
			end

			-- Ensure results are sorted by time in ascending order
			table.sort(worldTimes, function(a, b)
				return a.time < b.time
			end)

			-- Assign ranks based on sorted order
			for i, entry in ipairs(worldTimes) do
				entry.rank = i
			end

			-- Only return the top 2 entries for this world
			local topTwoEntries = {}
			for i = 1, math.min(2, #worldTimes) do
				table.insert(topTwoEntries, worldTimes[i])
			end

			results[worldName] = topTwoEntries
		else
			-- If there was an error or no times, return an empty array
			results[worldName] = {}
		end
	end

	return results
end

return Shared
