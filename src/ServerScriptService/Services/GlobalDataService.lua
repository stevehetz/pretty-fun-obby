local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Create appropriate DataStore prefix based on environment
local StorePrefix = RunService:IsStudio() and "Test_" or "Prod_"
local GlobalFinishersKey = StorePrefix .. "GlobalFinishers"
local PlayerInfoKey = StorePrefix .. "PlayerInfo"

local GlobalFinishesStore = DataStoreService:GetOrderedDataStore(GlobalFinishersKey)
local GlobalFinishesMemoryStore = MemoryStoreService:GetSortedMap(GlobalFinishersKey)
local PlayerInfoMemoryStore = MemoryStoreService:GetHashMap(PlayerInfoKey)

local GetTopFinishersRF = Instance.new("RemoteFunction")
GetTopFinishersRF.Name = "GetTopFinishers"
GetTopFinishersRF.Parent = ReplicatedStorage

local Local = {}
local Shared = {}

Shared.OnStart = function()
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

	GetTopFinishersRF.OnServerInvoke = function()
		return Shared.GetTopFinishers()
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

	return out
end

function Shared.RecordFinish(player, totalFinishes)
	local key = tostring(player.UserId)

	-- 1) Fetch the top 21 entries from the persistent store
	local ok, pages = pcall(function()
		return GlobalFinishesStore:GetSortedAsync(false, 21)
	end)
	if not ok then
		warn("Failed to fetch top entries for prune check:", pages)
		return
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

		-- b) Prune the 21st entry if it exists
		if countEntries >= 20 and entries[21] then
			pcall(function()
				GlobalFinishesStore:RemoveAsync(entries[21].key)
			end)
		end

		-- 4) Mirror into MemoryStore cache
		--    (we can reuse entries array length to know if we need to drop one)
		GlobalFinishesMemoryStore:UpdateAsync(key, function()
			return totalFinishes
		end, 86400) -- Cache for 24 hours
		if countEntries >= 20 and entries[21] then
			GlobalFinishesMemoryStore:RemoveAsync(entries[21].key)
		end

		-- 5) Pre-cache this player's info since they're on the leaderboard now
		task.spawn(function()
			Local.FetchAndCachePlayerInfo(player.UserId)
		end)
	end
end

return Shared
