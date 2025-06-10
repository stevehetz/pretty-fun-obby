local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local TestService = require(script.Parent.TestService)
local TrashcanService = require(script.Parent.TrashcanService)
local SwordService = require(script.Parent.SwordService)

local Local = {}
local Shared = {}

PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
	-- print("ToolsService - PlayerDataService.ProfileLoaded.Event")
	Shared.GiveTool(player, "Gravity Coil", 1157798560)
	Shared.GiveTool(player, "Speed Coil", 1157906298)

	-- Check if player has purchased a trashcan
	local state = PlayerDataService.GetState(player)
	if state and state.hasTrashcan then
		Shared.GiveTool(player, "Trashcan")
	elseif TestService.IsDev() then
		Shared.GiveTool(player, "Sword")
		Shared.GiveTool(player, "Trashcan")
	end

	player.CharacterAdded:Connect(function()
		Shared.GiveTool(player, "Gravity Coil", 1157798560)
		Shared.GiveTool(player, "Speed Coil", 1157906298)

		-- Check if player has purchased a trashcan
		local state = PlayerDataService.GetState(player)
		if state and state.hasTrashcan then
			Shared.GiveTool(player, "Trashcan")
		elseif TestService.IsDev() then
			Shared.GiveTool(player, "Trashcan")
			Shared.GiveTool(player, "Sword")
		end
	end)
end)

function Shared.GiveTool(player: Player, toolName: string, gamepassId: number?)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	-- Gamepass tool and player does not own the gamepass
	if gamepassId and not state.gamepasses[tostring(gamepassId)] then
		return
	end

	-- Not a gamepass tool or player owns the gamepass
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		return
	end

	local trashcan = ReplicatedStorage.Tools[toolName]:Clone()
	trashcan.Parent = backpack

	if toolName == "Trashcan" then
		TrashcanService.SetupTrashcan(player, trashcan)
	end

	if toolName == "Sword" then
		SwordService.SetupSword(player, trashcan)
	end
end

function Shared.EquipTool(player: Player, toolName: string)
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		return
	end

	local tool = backpack:FindFirstChild(toolName)
	if not tool then
		warn("Tool not found in backpack: ", toolName)
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	if not character then
		return
	end

	tool.Parent = character
	character.Humanoid:EquipTool(tool)
end

return Shared
