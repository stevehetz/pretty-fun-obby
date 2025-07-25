local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local StoreConfig = require(ServerStorage.Configs.Store)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.PlayerData.UpdateEquippedTrail.OnServerEvent:Connect(function(player, trail)
		Shared.UpdateEquippedTrails(player, trail)
	end)
end

function Shared.UpdateEquippedTrails(player: Player, trail: Trail)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local currentValue = state.equippedTrails[trail]
	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateEquippedTrails",
		trailName = trail,
		value = not currentValue,
	}

	PlayerDataService.UpdateState(player, action)
end

return Shared
