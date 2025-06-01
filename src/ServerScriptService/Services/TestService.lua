local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local GlobalDataService = require(ServerScriptService.Services.GlobalDataService)
local TestConfig = require(ReplicatedStorage.Configs.Test)

local Local = {}
local Shared = {}

Local.CurrentPlayer = nil

function Shared.OnStart()
	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		-- print("RespawnService - PlayerDataService.ProfileLoaded.Event")
		Local.CurrentPlayer = player
	end)
	-- task.wait(2)
	-- GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_zer0)
	-- GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test1)
	-- GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test2)
	-- GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test1)
	-- GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test2)
	-- Shared.AddTop50CoinRanks()
	-- task.wait(3)
	-- Shared.PrintCoinRank()
	-- Shared.AddTop50CoinRanks()
	-- print(GlobalDataService.GetCoinRank())
	-- task.wait(3)
	-- GlobalDataService.ClearGlobalStores()
	-- print(GlobalDataService.GetCoinRank())
	-- task.wait(3)
	Shared.AddTop50CoinRanks()
	-- task.wait(3)
	-- print(GlobalDataService.GetCoinRank())

	-- task.wait(1)
	Shared.AddTop50DonationRanks()
	-- task.wait(3)
	-- Shared.PrintDonationRank()
end

Shared.IsDev = function()
	if Local.CurrentPlayer then
		return TestConfig.IsDev(Local.CurrentPlayer.Name)
	end

	return false
end

function Shared.PrintCoinRank()
	local topRanks = GlobalDataService.GetCoinRank()
	print("Coin Rank: ", topRanks)
	-- print("Top Coin Ranks:")
	-- for _, rank in ipairs(topRanks) do
	-- 	print("UserId: " .. rank.userId .. ", Coins: " .. rank.coins)
	-- end
end

function Shared.AddTop50CoinRanks()
	-- Create a mock player table with UserId property
	local function createMockPlayer(userId)
		return {
			UserId = userId,
		}
	end

	-- Generate 50 random times between 3-7 minutes (180-420 seconds)
	for i = 1, 3 do
		-- Create a mock player with a unique UserId (starting from 1000)
		local mockPlayer = createMockPlayer(3000 + i)

		local randomCoinCount = math.random(1, 100000) * 100

		GlobalDataService.RecordCoinRank(mockPlayer, randomCoinCount)

		-- Print for debugging
		print("Added test coin rank for Player " .. mockPlayer.UserId .. ": " .. randomCoinCount .. " coins")
	end

	return true
end

function Shared.PrintDonationRank()
	local topRanks = GlobalDataService.GetDonationRank()
	print("Donation Rank: ", topRanks)
	-- print("Top Donation Ranks:")
	-- for _, rank in ipairs(topRanks) do
	-- 	print("UserId: " .. rank.userId .. ", Robux: " .. rank.robux)
	-- end
end

function Shared.AddTop50DonationRanks()
	-- Create a mock player table with UserId property
	local function createMockPlayer(userId)
		return {
			UserId = userId,
		}
	end

	-- Generate 50 random times between 3-7 minutes (180-420 seconds)
	for i = 1, 3 do
		-- Create a mock player with a unique UserId (starting from 1000)
		local mockPlayer = createMockPlayer(3000 + i)

		local randomDonationCount = math.random(1, 100000) * 100

		GlobalDataService.RecordDonationRank(mockPlayer, randomDonationCount)

		-- Print for debugging
		print("Added test donation rank for Player " .. mockPlayer.UserId .. ": " .. randomDonationCount .. " Robux")
	end

	return true
end

return Shared
