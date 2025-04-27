local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GlobalDataService = require(ServerScriptService.Services.GlobalDataService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.TimedFinish.OnServerEvent:Connect(Local.TimedFinish)
end

function Local.TimedFinish(player: Player, time: number)
	GlobalDataService.RecordTime(player, time)
end

return Shared
