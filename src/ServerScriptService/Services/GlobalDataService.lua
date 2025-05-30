local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)

-- Create appropriate DataStore prefix based on environment
local StorePrefix = RunService:IsStudio() and "Test_" or "Prod_"
local GlobalCoinRankKey = StorePrefix .. "GlobalCoinRank"
local PlayerInfoKey = StorePrefix .. "PlayerInfo"

local GlobalCoinRankDataStore = DataStoreService:GetOrderedDataStore(GlobalCoinRankKey)
local GlobalCoinRankMemoryStore = MemoryStoreService:GetSortedMap(GlobalCoinRankKey)
local PlayerInfoMemoryStore = MemoryStoreService:GetHashMap(PlayerInfoKey)

local GetCoinRankRF = Instance.new("RemoteFunction")
GetCoinRankRF.Name = "GetCoinRankRF"
GetCoinRankRF.Parent = ReplicatedStorage

local Local = {}
local Shared = {}

Shared.OnStart = function()
	-- Get top coins from the persistent store and cache them in MemoryStore
	task.spawn(function()
		local success, pages = pcall(function()
			return GlobalCoinRankDataStore:GetSortedAsync(false, 20)
		end)

		if success then
			for _, entry in ipairs(pages:GetCurrentPage()) do
				-- entry.key is userId string, entry.value is their count
				GlobalCoinRankMemoryStore:UpdateAsync(entry.key, function()
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

	GetCoinRankRF.OnServerInvoke = function()
		return Shared.GetCoinRank()
	end
end

-- Function to clear all entries from both global stores
function Shared.ClearGlobalStores()
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
			print(
				"Cleared " .. successCount .. " entries from " .. storeName .. ". " .. failCount .. " entries failed."
			)
		else
			warn("Failed to fetch entries for clearing " .. storeName .. ":", pages)
		end
	end

	clearOrderedDataStore(GlobalCoinRankDataStore, GlobalCoinRankMemoryStore, "GlobalCoinRank")

	return true
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

function Shared.GetCoinRank()
	local ok, list = pcall(function()
		return GlobalCoinRankMemoryStore:GetRangeAsync(Enum.SortDirection.Descending, 40)
	end)
	if not ok then
		return {}
	end

	local out = {}
	for _, entry in ipairs(list) do
		local uid = tonumber(entry.key)
		local coins = entry.value

		-- Get player info (from cache if available)
		local playerInfo = Local.FetchAndCachePlayerInfo(uid)

		table.insert(out, {
			userId = uid,
			username = playerInfo.username,
			avatarUrl = playerInfo.avatarUrl,
			coins = coins,
		})
	end

	-- Ensure results are sorted by coins in descending order
	table.sort(out, function(a, b)
		return a.coins > b.coins
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

function Shared.RecordCoinRank(player, totalCoins)
	local key = tostring(player.UserId)

	-- 1) Fetch the top 21 entries from the persistent store
	local ok, pages = pcall(function()
		return GlobalCoinRankDataStore:GetSortedAsync(false, 20)
	end)
	if not ok then
		warn("Failed to fetch top entries for prune check:", pages)
		return
	end

	-- -- print top 20 coins for debugging
	-- for index, entry in ipairs(pages:GetCurrentPage()) do
	-- 	print(index .. ":", entry.key, entry.value)
	-- end

	local isPlayerAlreadyOnLeaderboard = false
	local currentCoins = 0

	for _, entry in ipairs(pages:GetCurrentPage()) do
		if entry.key == key then
			isPlayerAlreadyOnLeaderboard = true
			currentCoins = entry.value
			break
		end
	end

	-- If player is already on leaderboard and has more coins than the new value,
	-- don't update the leaderboard
	if isPlayerAlreadyOnLeaderboard and totalCoins <= currentCoins then
		return
	end

	local entries = pages:GetCurrentPage()
	local countEntries = #entries

	-- 2) Determine the cutoff: if fewer than 20 entries, anyone qualifies
	local cutoff = (countEntries < 20) and -math.huge or entries[20].value

	-- 3) Only set/prune if this player's totalCoins beats the cutoff
	if totalCoins > cutoff then
		-- a) Write into the persistent OrderedDataStore
		local sOk, sErr = pcall(function()
			GlobalCoinRankDataStore:SetAsync(key, totalCoins)
		end)
		if not sOk then
			warn("Failed to set global coin rank for", key, sErr)
		end

		-- First remove the key from MemoryStore to clear any cached value
		pcall(function()
			GlobalCoinRankMemoryStore:RemoveAsync(key)
		end)

		-- Then add the new value
		GlobalCoinRankMemoryStore:UpdateAsync(key, function()
			return totalCoins
		end, 86400) -- Cache for 24 hours

		-- b) Prune the now 21st entry if it exists from the persistent store and MemoryStore
		if not isPlayerAlreadyOnLeaderboard and countEntries >= 20 and entries[20] then
			pcall(function()
				GlobalCoinRankDataStore:RemoveAsync(entries[20].key)
			end)

			GlobalCoinRankMemoryStore:RemoveAsync(entries[20].key)
		end

		-- 5) Pre-cache this player's info since they're on the leaderboard now
		task.spawn(function()
			Local.FetchAndCachePlayerInfo(player.UserId)
		end)
	end
end

return Shared
