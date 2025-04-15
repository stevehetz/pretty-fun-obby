local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RespawnService = require(script.Parent.RespawnService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.Rebirth.OnServerEvent:Connect(Shared.Rebirth)
end

function Shared.Rebirth(player: Player)
	RespawnService.RestartPlayer(player)
end

return Shared
