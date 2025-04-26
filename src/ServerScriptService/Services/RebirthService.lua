local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RespawnService = require(script.Parent.RespawnService)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.Rebirth.OnServerEvent:Connect(Shared.Rebirth)
end

function Shared.Rebirth(player: Player)
	RespawnService.RestartPlayer(player)

	-- For testing only
	-- local action = {
	-- 	type = "UpdateFinishes",
	-- 	amount = 1,
	-- }
	-- PlayerDataService.UpdateState(player, action)
end

return Shared
