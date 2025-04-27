local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ReplicatedStorage.PlayerData)
local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local GlobalDataService = require(ServerScriptService.Services.GlobalDataService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.WorldFinish.OnServerEvent:Connect(Local.WorldFinish)
	Remotes.TimedFinish.OnServerEvent:Connect(Local.TimedFinish)
end

function Local.WorldFinish(player: Player)
	-- get state
	local playerState: PlayerData.PlayerData = PlayerDataService.GetState(player)

	local currentWorld = WorldsConfig.GetCurrentWorldName()

	local action = {
		type = "UpdateWorldFinishes",
		world = currentWorld,
		amount = 1,
	}

	PlayerDataService.UpdateState(player, action)

	GlobalDataService.RecordWorldFinish(player, playerState.worldFinishes[currentWorld])
end

function Local.TimedFinish(player: Player, time: number)
	GlobalDataService.RecordTimeFinish(player, time)
end

return Shared
