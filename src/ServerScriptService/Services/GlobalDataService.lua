local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Create appropriate DataStore prefix based on environment
local StorePrefix = RunService:IsStudio() and "Test_" or "Prod_"
local PlayerInfoKey = StorePrefix .. "PlayerInfo"
local PlayerInfoMemoryStore = MemoryStoreService:GetHashMap(PlayerInfoKey)

local Local = {}
local Shared = {}

local MAX_ENTRIES = 50

-- Define leaderboard configurations
local LeaderboardConfig = {
	coin = {
		key = StorePrefix .. "GlobalCoinRank",
		valueName = "coins",
		dataStore = nil, -- Will be set during initialization
		memoryStore = nil, -- Will be set during initialization
		cacheKey = "coinRank",
		lastUpdateKey = "lastCoinRankUpdate",
		refreshFunction = "RefreshCoinRankCache",
		getFunction = "GetCoinRank",
		recordFunction = "RecordCoinRank",
	},
	donation = {
		key = StorePrefix .. "GlobalDonationRank",
		valueName = "robux",
		dataStore = nil, -- Will be set during initialization
		memoryStore = nil, -- Will be set during initialization
		cacheKey = "donationRank",
		lastUpdateKey = "lastDonationRankUpdate",
		refreshFunction = "RefreshDonationRankCache",
		getFunction = "GetDonationRank",
		recordFunction = "RecordDonationRank",
	},
}

-- Initialize remote functions
local GetCoinRankRF = Instance.new("RemoteFunction")
GetCoinRankRF.Name = "GetCoinRankRF"
GetCoinRankRF.Parent = ReplicatedStorage

local GetDonationRankRF = Instance.new("RemoteFunction")
GetDonationRankRF.Name = "GetDonationRankRF"
GetDonationRankRF.Parent = ReplicatedStorage

-- Initialize DataStores and MemoryStores
LeaderboardConfig.coin.dataStore = DataStoreService:GetOrderedDataStore(LeaderboardConfig.coin.key)
LeaderboardConfig.coin.memoryStore = MemoryStoreService:GetSortedMap(LeaderboardConfig.coin.key)
LeaderboardConfig.donation.dataStore = DataStoreService:GetOrderedDataStore(LeaderboardConfig.donation.key)
LeaderboardConfig.donation.memoryStore = MemoryStoreService:GetSortedMap(LeaderboardConfig.donation.key)

-- Add local caching to reduce MemoryStore calls
local LocalCache = {
	playerInfo = {}, -- Cache player info locally
	coinRank = {}, -- Cache coin rank data
	donationRank = {}, -- Cache donation rank data
	lastCoinRankUpdate = 0,
	lastDonationRankUpdate = 0,
	updateInterval = 60, -- Update leaderboards every 60 seconds
}

-- Generic function to bootstrap a leaderboard from DataStore to MemoryStore
local function BootstrapLeaderboard(config)
	local success, pages = pcall(function()
		return config.dataStore:GetSortedAsync(false, MAX_ENTRIES)
	end)

	if success then
		for _, entry in ipairs(pages:GetCurrentPage()) do
			-- entry.key is userId string, entry.value is their count
			config.memoryStore:UpdateAsync(entry.key, function()
				return entry.value
			end, 86400) -- Cache for 24 hours

			-- Pre-cache player info for top players
			task.spawn(function()
				Local.FetchAndCachePlayerInfo(entry.key)
			end)
		end
	else
		warn(config.key .. " leaderboard bootstrap failed: ", pages)
	end
end

Shared.OnStart = function()
	-- Bootstrap coin leaderboard
	task.spawn(function()
		BootstrapLeaderboard(LeaderboardConfig.coin)
	end)

	-- Bootstrap donation leaderboard
	task.spawn(function()
		BootstrapLeaderboard(LeaderboardConfig.donation)
	end)

	-- Set up RemoteFunction handlers
	GetCoinRankRF.OnServerInvoke = function()
		return Shared.GetCoinRank()
	end

	GetDonationRankRF.OnServerInvoke = function()
		return Shared.GetDonationRank()
	end

	-- Set up periodic refresh of leaderboard data to reduce on-demand requests
	task.spawn(function()
		while true do
			task.wait(LocalCache.updateInterval)

			-- Update leaderboard caches in the background
			for leaderboardType, config in pairs(LeaderboardConfig) do
				if os.time() - LocalCache[config.lastUpdateKey] > LocalCache.updateInterval then
					Shared[config.refreshFunction]()
				end
			end
		end
	end)
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

	-- Clear all leaderboard DataStores and MemoryStores
	for leaderboardType, config in pairs(LeaderboardConfig) do
		clearDataStore(config.dataStore, config.key)
		clearMemoryStore(config.memoryStore, config.key)
	end

	return true
end

-- Helper function to fetch and cache player info
function Local.FetchAndCachePlayerInfo(userId)
	userId = tostring(userId)
	local uid = tonumber(userId)

	-- Check local cache first
	if LocalCache.playerInfo[userId] and os.time() - LocalCache.playerInfo[userId].lastUpdated < 3600 then
		return LocalCache.playerInfo[userId]
	end

	-- Try to get cached info from MemoryStore
	local ok, cachedInfo = pcall(function()
		return PlayerInfoMemoryStore:GetAsync(userId)
	end)

	-- If we have cached info from MemoryStore, update local cache and return it
	if ok and cachedInfo then
		LocalCache.playerInfo[userId] = cachedInfo
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

	-- Update local cache
	LocalCache.playerInfo[userId] = playerInfo

	-- Cache the player info for 24 hours in MemoryStore (with throttling protection)
	task.spawn(function()
		pcall(function()
			PlayerInfoMemoryStore:SetAsync(userId, playerInfo, 86400)
		end)
	end)

	return playerInfo
end

-- Generic function to refresh a leaderboard cache
local function RefreshLeaderboardCache(config)
	local ok, list = pcall(function()
		return config.memoryStore:GetRangeAsync(Enum.SortDirection.Descending, MAX_ENTRIES)
	end)

	if not ok then
		return
	end

	local out = {}
	for _, entry in ipairs(list) do
		local uid = tonumber(entry.key)
		local value = entry.value

		-- Get player info (from cache if available)
		local playerInfo = Local.FetchAndCachePlayerInfo(uid)

		local entryData = {
			userId = uid,
			username = playerInfo.username,
			avatarUrl = playerInfo.avatarUrl,
		}

		-- Set the appropriate value field (coins or robux)
		entryData[config.valueName] = value

		table.insert(out, entryData)
	end

	-- Ensure results are sorted by value in descending order
	table.sort(out, function(a, b)
		return a[config.valueName] > b[config.valueName]
	end)

	-- Assign ranks based on sorted order
	for i, entry in ipairs(out) do
		entry.rank = i
	end

	local topEntries = {}
	for i = 1, math.min(MAX_ENTRIES, #out) do
		table.insert(topEntries, out[i])
	end

	LocalCache[config.cacheKey] = topEntries
	LocalCache[config.lastUpdateKey] = os.time()
end

-- Function to refresh coin rank cache in the background
function Shared.RefreshCoinRankCache()
	RefreshLeaderboardCache(LeaderboardConfig.coin)
end

function Shared.GetCoinRank()
	-- If cache is empty or stale, refresh it
	if #LocalCache.coinRank == 0 or os.time() - LocalCache.lastCoinRankUpdate > LocalCache.updateInterval then
		Shared.RefreshCoinRankCache()
	end

	return LocalCache.coinRank
end

-- Function to refresh donation rank cache in the background
function Shared.RefreshDonationRankCache()
	RefreshLeaderboardCache(LeaderboardConfig.donation)
end

function Shared.GetDonationRank()
	-- If cache is empty or stale, refresh it
	if #LocalCache.donationRank == 0 or os.time() - LocalCache.lastDonationRankUpdate > LocalCache.updateInterval then
		Shared.RefreshDonationRankCache()
	end

	return LocalCache.donationRank
end

-- Generic function to record a rank
local function RecordLeaderboardRank(config, player, totalValue)
	local key = tostring(player.UserId)

	-- 1) Fetch the top entries from the persistent store
	local ok, pages = pcall(function()
		return config.dataStore:GetSortedAsync(false, MAX_ENTRIES + 10)
	end)
	if not ok then
		warn("Failed to fetch top entries for " .. config.key .. " prune check:", pages)
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
	local cutoff = (countEntries < MAX_ENTRIES) and -math.huge or entries[math.min(MAX_ENTRIES, countEntries)].value

	-- 3) Only set/prune if this player's total value beats the cutoff
	if totalValue > cutoff then
		-- a) Write into the persistent OrderedDataStore
		local sOk, sErr = pcall(function()
			config.dataStore:SetAsync(key, totalValue)
		end)
		if not sOk then
			warn("Failed to set " .. config.key .. " for", key, sErr)
		end

		-- Update the value directly without removing first
		local updateSuccess, updateError = pcall(function()
			config.memoryStore:UpdateAsync(key, function()
				return totalValue
			end, 86400) -- Cache for 24 hours
		end)

		if not updateSuccess then
			warn(
				"Failed to update "
					.. config.key
					.. " in MemoryStore for player "
					.. key
					.. ": "
					.. tostring(updateError)
			)
		end

		-- Prune memorystore to MAX_ENTRIES, but do it less frequently
		-- Only prune if this is a significant update (player is likely to be on leaderboard)
		if totalValue > cutoff * 0.8 then
			local msOk, msList = pcall(function()
				return config.memoryStore:GetRangeAsync(Enum.SortDirection.Descending, MAX_ENTRIES + 5)
			end)

			if msOk and #msList > MAX_ENTRIES then
				-- Sort by value (descending)
				table.sort(msList, function(a, b)
					return a.value > b.value
				end)

				-- Remove entries beyond MAX_ENTRIES
				for i = MAX_ENTRIES + 1, #msList do
					task.spawn(function()
						pcall(function()
							config.memoryStore:RemoveAsync(msList[i].key)
						end)
					end)
				end
			end
		end

		-- b) Prune the entry at MAX_ENTRIES if it exists in the persistent store and MemoryStore
		if not isPlayerAlreadyOnLeaderboard and countEntries >= MAX_ENTRIES and entries[MAX_ENTRIES] then
			pcall(function()
				config.dataStore:RemoveAsync(entries[MAX_ENTRIES].key)
			end)

			config.memoryStore:RemoveAsync(entries[MAX_ENTRIES].key)
		end

		-- 4) Pre-cache this player's info since they're on the leaderboard now
		Local.FetchAndCachePlayerInfo(player.UserId)

		-- Force refresh the leaderboard cache
		task.spawn(function()
			Shared[config.refreshFunction]()
		end)
	end
end

function Shared.RecordCoinRank(player, totalCoins)
	RecordLeaderboardRank(LeaderboardConfig.coin, player, totalCoins)
end

function Shared.RecordDonationRank(player, totalRobux)
	RecordLeaderboardRank(LeaderboardConfig.donation, player, totalRobux)
end

return Shared
