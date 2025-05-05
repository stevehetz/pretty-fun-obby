local ServerScriptService = game:GetService("ServerScriptService")

local GlobalDataService = require(ServerScriptService.Services.GlobalDataService)

local Local = {}
local Shared = {}

function Shared.OnStart()
	task.wait(5)
	-- Shared.AddTopTwentyTimes()
	Shared.RecordOneTime()
end

function Shared.RecordOneTime()
	local player = {
		UserId = 1130,
	}
	local time = 170
	GlobalDataService.RecordTimeFinish(player, time)
	print("Recorded time for Player " .. player.UserId .. ": " .. time .. " seconds")
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
