local ServerScriptService = game:GetService("ServerScriptService")

local GlobalDataService = require(ServerScriptService.Services.GlobalDataService)

local Local = {}
local Shared = {}

function Shared.OnStart()
	-- task.wait(5)
	-- Shared.RecordOneFinish()
	-- Shared.RecordOneTime()
	-- Shared.AddTopTwentyFinishes()
	-- Shared.AddTopTwentyTimes()
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
		UserId = 2345349,
	}
	local time = 168
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
