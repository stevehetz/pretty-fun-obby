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
	GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_zer0)
	GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test1)
	GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test2)
	-- GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test1)
	-- GlobalDataService.RemovePlayerFromTimeLeaderboard(TestConfig.Players.ra1n_test2)
	-- Shared.PrintTopTimes()
	-- task.wait(3)
	-- Shared.RecordOneFinish()
	-- Shared.RecordOneTime()
	-- Shared.AddTopTwentyFinishes()
	-- Shared.AddTopTwentyTimes()
end

Shared.IsDev = function()
	if Local.CurrentPlayer then
		return TestConfig.IsDev(Local.CurrentPlayer.Name)
	end

	return false
end

function Shared.PrintTopTimes()
	local topTimes = GlobalDataService.GetTopTimes()
	print("Top Times:")
	for _, time in ipairs(topTimes) do
		print("UserId: " .. time.userId .. ", Time: " .. time.time)
	end
end

function Shared.RecordOneFinish()
	local player = {
		UserId = 113111,
	}
	local finishCount = 14
	GlobalDataService.RecordWorldFinish(player, finishCount)
	print("Recorded finish for Player " .. player.UserId .. ": " .. finishCount)
end

function Shared.RecordOneTime()
	local player = {
		UserId = 2345340,
	}
	local time = 207
	GlobalDataService.RecordTimeFinish(player, time)
	print("Recorded time for Player " .. player.UserId .. ": " .. time .. " seconds")
end

function Shared.AddTopTwentyFinishes()
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

		-- Generate random finishes between 3-7
		local randomFinishCount = math.random(3, 7)

		-- Record the time finish
		GlobalDataService.RecordWorldFinish(mockPlayer, randomFinishCount)

		-- Print for debugging
		print("Added test finishes for Player " .. mockPlayer.UserId .. ": " .. randomFinishCount)
	end

	print("Added 20 test times to the leaderboard")
	return true
end

function Shared.AddTopTwentyTimes()
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

		-- Generate a random time between 3-7 minutes (180-420 seconds)
		local randomTime = 180 + math.random() * 240

		-- Round to 2 decimal places for cleaner times
		randomTime = math.floor(randomTime * 100) / 100

		-- Record the time finish
		GlobalDataService.RecordTimeFinish(mockPlayer, randomTime)

		-- Print for debugging
		print("Added test time for Player " .. mockPlayer.UserId .. ": " .. randomTime .. " seconds")
	end

	print("Added 20 test times to the leaderboard")
	return true
end

return Shared
