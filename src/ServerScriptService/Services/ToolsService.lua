local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local StoreService = require(script.Parent.StoreService)

local Local = {}
local Shared = {}

PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
	-- print("ToolsService - PlayerDataService.ProfileLoaded.Event")
	Shared.GiveTool(player, "Gravity Coil", 1157798560)
	Shared.GiveTool(player, "Speed Coil", 1157906298)

	player.CharacterAdded:Connect(function(character)
		Shared.GiveTool(player, "Gravity Coil", 1157798560)
		Shared.GiveTool(player, "Speed Coil", 1157906298)
	end)
end)

function Shared.GiveTool(player: Player, toolName: string, gamepassId: number)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local playerOwnsGamepass = state.gamepasses[gamepassId] or false
	local ownsTool = playerOwnsGamepass
	if not ownsTool then
		return
	end

	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		return
	end

	local clone = ReplicatedStorage.Tools[toolName]:Clone()
	clone.Parent = backpack
end

return Shared
