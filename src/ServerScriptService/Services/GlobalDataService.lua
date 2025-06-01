local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)

-- Create appropriate DataStore prefix based on environment
local StorePrefix = RunService:IsStudio() and "Test_" or "Prod_"
local GlobalCoinRankKey = StorePrefix .. "GlobalCoinRank"
local GlobalDonationRankKey = StorePrefix .. "GlobalDonationRank"
local PlayerInfoKey = StorePrefix .. "PlayerInfo"

local GlobalCoinRankDataStore = DataStoreService:GetOrderedDataStore(GlobalCoinRankKey)
local GlobalCoinRankMemoryStore = MemoryStoreService:GetSortedMap(GlobalCoinRankKey)
local GlobalDonationRankDataStore = DataStoreService:GetOrderedDataStore(GlobalDonationRankKey)
local GlobalDonationRankMemoryStore = MemoryStoreService:GetSortedMap(GlobalDonationRankKey)
local PlayerInfoMemoryStore = MemoryStoreService:GetHashMap(PlayerInfoKey)

local GetCoinRankRF = Instance.new("RemoteFunction")
GetCoinRankRF.Name = "GetCoinRankRF"
GetCoinRankRF.Parent = ReplicatedStorage

local GetDonationRankRF = Instance.new("RemoteFunction")
GetDonationRankRF.Name = "GetDonationRankRF"
GetDonationRankRF.Parent = ReplicatedStorage

local Local = {}
local Shared = {}

local MAX_ENTRIES = 50
local CLEANUP_INTERVAL = 86400 -- 24 hours in seconds

Shared.OnStart = function()
	-- Get top coins from the persistent store and cache them in MemoryStore
	task.spawn(function()
		local success, pages = pcall(function()
			return GlobalCoinRankDataStore:GetSortedAsync(false, MAX_ENTRIES)
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
			warn("Coin leaderboard bootstrap failed: ", pages)
		end
	end)

	-- Get top donations from the persistent store and cache them in MemoryStore
	task.spawn(function()
		local success, pages = pcall(function()
			return GlobalDonationRankDataStore:GetSortedAsync(false, MAX_ENTRIES)
		end)

		if success then
			for _, entry in ipairs(pages:GetCurrentPage()) do
				-- entry.key is userId string, entry.value is their count
				GlobalDonationRankMemoryStore:UpdateAsync(entry.key, function()
					return entry.value
				end, 86400) -- Cache for 24 hours

				-- Pre-cache player info for top players
				task.spawn(function()
					Local.FetchAndCachePlayerInfo(entry.key)
				end)
			end
		else
			warn("Donation leaderboard bootstrap failed: ", pages)
		end
	end)

	GetCoinRankRF.OnServerInvoke = function()
		return Shared.GetCoinRank()
	end

	GetDonationRankRF.OnServerInvoke = function()
		return Shared.GetDonationRank()
	end
end

-- Function to clear all entries from both global stores
function Shared.ClearGlobalStores()
	-- Function to clear entries from a DataStore
	local function clearDataStore(store, storeName)
		local success, pages = pcall(function()
			return store:GetSortedAsync(false, MAX_ENTRIES)
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

				if dsSuccess then
					successCount = successCount + 1
				else
					failCount = failCount + 1
				end
			end

			print(
				"Cleared "
					.. successCount
					.. " entries from "
					.. storeName
					.. " DataStore. "
					.. failCount
					.. " entries failed."
			)

			return entries
		else
			warn("Failed to fetch entries for clearing " .. storeName .. " DataStore:", pages)
			return {}
		end
	end

	-- Function to clear entries from a MemoryStore
	local function clearMemoryStore(memoryStore, storeName)
		local successCount = 0
		local failCount = 0

		-- Get entries directly from MemoryStore
		local msSuccess, msEntries = pcall(function()
			return memoryStore:GetRangeAsync(Enum.SortDirection.Descending, MAX_ENTRIES)
		end)

		if msSuccess then
			for _, entry in ipairs(msEntries) do
				-- Remove from MemoryStore
				local success = pcall(function()
					memoryStore:RemoveAsync(entry.key)
				end)

				if success then
					successCount = successCount + 1
				else
					failCount = failCount + 1
				end
			end

			print(
				"Cleared "
					.. successCount
					.. " entries from "
					.. storeName
					.. " MemoryStore. "
					.. failCount
					.. " entries failed."
			)
		else
			warn("Failed to fetch entries for clearing " .. storeName .. " MemoryStore")
		end
	end

	-- Clear DataStores first
	clearDataStore(GlobalCoinRankDataStore, "GlobalCoinRank")
	clearDataStore(GlobalDonationRankDataStore, "GlobalDonationRank")

	-- Then clear MemoryStores separately
	clearMemoryStore(GlobalCoinRankMemoryStore, "GlobalCoinRank")
	clearMemoryStore(GlobalDonationRankMemoryStore, "GlobalDonationRank")

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
		return GlobalCoinRankMemoryStore:GetRangeAsync(Enum.SortDirection.Descending, MAX_ENTRIES + 10)
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

	print(out)

	-- Assign ranks based on sorted order
	for i, entry in ipairs(out) do
		entry.rank = i
	end

	local topEntries = {}
	for i = 1, math.min(MAX_ENTRIES, #out) do
		table.insert(topEntries, out[i])
	end

	return topEntries
end

function Shared.GetDonationRank()
	local ok, list = pcall(function()
		return GlobalDonationRankMemoryStore:GetRangeAsync(Enum.SortDirection.Descending, MAX_ENTRIES + 10)
	end)
	if not ok then
		return {}
	end

	local out = {}
	for _, entry in ipairs(list) do
		local uid = tonumber(entry.key)
		local robux = entry.value

		-- Get player info (from cache if available)
		local playerInfo = Local.FetchAndCachePlayerInfo(uid)

		table.insert(out, {
			userId = uid,
			username = playerInfo.username,
			avatarUrl = playerInfo.avatarUrl,
			robux = robux,
		})
	end

	-- Ensure results are sorted by robux in descending order
	table.sort(out, function(a, b)
		return a.robux > b.robux
	end)

	print(out)

	-- Assign ranks based on sorted order
	for i, entry in ipairs(out) do
		entry.rank = i
	end

	local topEntries = {}
	for i = 1, math.min(MAX_ENTRIES, #out) do
		table.insert(topEntries, out[i])
	end

	return topEntries
end

function Shared.RecordCoinRank(player, totalCoins)
	local key = tostring(player.UserId)

	-- 1) Fetch the top entries from the persistent store
	local ok, pages = pcall(function()
		return GlobalCoinRankDataStore:GetSortedAsync(false, MAX_ENTRIES + 10)
	end)
	if not ok then
		warn("Failed to fetch top entries for prune check:", pages)
		return
	end

	local isPlayerAlreadyOnLeaderboard = false

	for _, entry in ipairs(pages:GetCurrentPage()) do
		if entry.key == key then
			isPlayerAlreadyOnLeaderboard = true
			break
		end
	end

	local entries = pages:GetCurrentPage()
	local countEntries = #entries

	print("Count entries: ", countEntries)

	-- 2) Determine the cutoff: if fewer than MAX_ENTRIES entries, anyone qualifies
	local cutoff = (countEntries < MAX_ENTRIES) and -math.huge or entries[MAX_ENTRIES].value

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
		local updateSuccess, updateError = pcall(function()
			GlobalCoinRankMemoryStore:UpdateAsync(key, function()
				return totalCoins
			end, 86400) -- Cache for 24 hours
		end)

		if not updateSuccess then
			warn("Failed to update coin rank in MemoryStore for player " .. key .. ": " .. tostring(updateError))
		end

		-- b) Prune the entry at MAX_ENTRIES if it exists in the persistent store and MemoryStore
		if not isPlayerAlreadyOnLeaderboard and countEntries >= MAX_ENTRIES and entries[MAX_ENTRIES] then
			pcall(function()
				print("Pruning entry at MAX_ENTRIES: ", entries[MAX_ENTRIES].key)
				GlobalCoinRankDataStore:RemoveAsync(entries[MAX_ENTRIES].key)
			end)

			print("Removing from MemoryStore: ", entries[MAX_ENTRIES].key)
			GlobalCoinRankMemoryStore:RemoveAsync(entries[MAX_ENTRIES].key)
		end

		-- 4) Pre-cache this player's info since they're on the leaderboard now
		task.spawn(function()
			Local.FetchAndCachePlayerInfo(player.UserId)
		end)
	end
end

function Shared.RecordDonationRank(player, totalRobux)
	local key = tostring(player.UserId)

	-- 1) Fetch the top entries from the persistent store
	local ok, pages = pcall(function()
		return GlobalDonationRankDataStore:GetSortedAsync(false, MAX_ENTRIES)
	end)
	if not ok then
		warn("Failed to fetch top entries for donation prune check:", pages)
		return
	end

	local isPlayerAlreadyOnLeaderboard = false

	for _, entry in ipairs(pages:GetCurrentPage()) do
		if entry.key == key then
			isPlayerAlreadyOnLeaderboard = true
			break
		end
	end

	local entries = pages:GetCurrentPage()
	local countEntries = #entries

	-- 2) Determine the cutoff: if fewer than MAX_ENTRIES entries, anyone qualifies
	local cutoff = (countEntries < MAX_ENTRIES) and -math.huge or entries[MAX_ENTRIES].value

	-- 3) Only set/prune if this player's totalRobux beats the cutoff
	if totalRobux > cutoff then
		-- a) Write into the persistent OrderedDataStore
		local sOk, sErr = pcall(function()
			GlobalDonationRankDataStore:SetAsync(key, totalRobux)
		end)
		if not sOk then
			warn("Failed to set global donation rank for", key, sErr)
		end

		-- First remove the key from MemoryStore to clear any cached value
		pcall(function()
			GlobalDonationRankMemoryStore:RemoveAsync(key)
		end)

		-- Then add the new value
		local updateSuccess, updateError = pcall(function()
			GlobalDonationRankMemoryStore:UpdateAsync(key, function()
				return totalRobux
			end, 86400) -- Cache for 24 hours
		end)

		if not updateSuccess then
			warn("Failed to update donation rank in MemoryStore for player " .. key .. ": " .. tostring(updateError))
		end

		-- b) Prune the entry at MAX_ENTRIES if it exists in the persistent store and MemoryStore
		if not isPlayerAlreadyOnLeaderboard and countEntries >= MAX_ENTRIES and entries[MAX_ENTRIES] then
			pcall(function()
				GlobalDonationRankDataStore:RemoveAsync(entries[MAX_ENTRIES].key)
			end)

			GlobalDonationRankMemoryStore:RemoveAsync(entries[MAX_ENTRIES].key)
		end

		-- 4) Pre-cache this player's info since they're on the leaderboard now
		task.spawn(function()
			Local.FetchAndCachePlayerInfo(player.UserId)
		end)
	end
end

return Shared
