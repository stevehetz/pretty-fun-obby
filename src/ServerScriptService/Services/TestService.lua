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
	-- Shared.AddTop20CoinRanks()
	-- task.wait(3)
	-- Shared.PrintCoinRank()
	print(GlobalDataService.GetCoinRank())
end

Shared.IsDev = function()
	if Local.CurrentPlayer then
		return TestConfig.IsDev(Local.CurrentPlayer.Name)
	end

	return false
end

function Shared.PrintCoinRank()
	local topRanks = GlobalDataService.GetCoinRank()
	print("Top Coin Ranks:")
	for _, rank in ipairs(topRanks) do
		print("UserId: " .. rank.userId .. ", Coins: " .. rank.coins)
	end
end

function Shared.AddTop20CoinRanks()
	-- Create a mock player table with UserId property
	local function createMockPlayer(userId)
		return {
			UserId = userId,
		}
	end

	-- Generate 20 random times between 3-7 minutes (180-420 seconds)
	for i = 1, 20 do
		-- Create a mock player with a unique UserId (starting from 1000)
		local mockPlayer = createMockPlayer(1000 + i)

		-- Generate random coin count between 1000 and 1000000000
		-- round to the nearest 1000 for cleaner numbers
		local randomCoinCount = math.floor(1000 + math.random() * 999999000 / 1000) * 1000

		-- Record the time finish
		GlobalDataService.RecordCoinRank(mockPlayer, randomCoinCount)

		-- Print for debugging
		print("Added test coin rank for Player " .. mockPlayer.UserId .. ": " .. randomCoinCount .. " coins")
	end

	return true
end

return Shared
