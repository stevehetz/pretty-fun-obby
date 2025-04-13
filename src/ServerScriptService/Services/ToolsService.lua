local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local StoreConfig = require(ReplicatedStorage.Configs.Store)

local Local = {}
local Shared = {}

PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
	Shared.GiveTool(player, "Gravity Coil")
	Shared.GiveTool(player, "Speed Coil")

	player.CharacterAdded:Connect(function(character)
		Shared.GiveTool(player, "Gravity Coil")
		Shared.GiveTool(player, "Speed Coil")
	end)
end)

function Shared.GiveTool(player: Player, tool: StoreConfig.GamepassName)
	local state = PlayerDataService.GetState(player)
	if not state then return end

	local ownsTool = StoreConfig.DoesPlayerOwnGamepass(state, tool)
	if not ownsTool then
		return
	end

	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then return end

	local clone = ReplicatedStorage.Tools[tool]:Clone()
	clone.Parent = backpack
end

return Shared
