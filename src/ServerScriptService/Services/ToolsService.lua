local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local TestConfig = require(ReplicatedStorage.Configs.Test)
local TrashcanService = require(script.Parent.TrashcanService)
local SwordService = require(script.Parent.SwordService)

local Local = {}
local Shared = {}

PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
	player.CharacterAdded:Connect(function()
		Local.GiveTools(player)
	end)

	Local.GiveTools(player)
end)

function Local.GiveTools(player: Player)
	-- print("Giving tools to player: ", player.Name)
	task.wait(0.3)
	Shared.GiveTool(player, "Gravity Coil", 1157798560)
	task.wait(0.3)
	Shared.GiveTool(player, "Speed Coil", 1157906298)
	task.wait(0.3)
	Shared.GiveTool(player, "Sword", 1255668315)
	task.wait(0.3)

	-- Get player state
	local state = PlayerDataService.GetState(player)

	-- Check if player has purchased a sword
	task.wait(0.3)

	-- Check if player has purchased a trashcan
	if state and state.hasTrashcan then
		print("Giving trashcan to player: ", player.Name)
		Shared.GiveTool(player, "Trashcan")
	end

	if TestConfig.IsDev(player.Name) then
		-- Shared.GiveTool(player, "Trashcan")
		-- Shared.GiveTool(player, "Sword")
	end

	if TestConfig.IsTester(player.Name) then
		-- print("Giving sword to tester: ", player.Name)
		-- Shared.GiveTool(player, "Sword")
	end
end

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
		warn("Backpack not found for player: ", player.Name)
		return
	end

	-- Make sure player doesn't have tool in backpack
	if backpack:FindFirstChild(toolName) then
		warn("Tool already exists in backpack: ", toolName, " for player: ", player.Name)
		return
	end

	-- Make sure player is not holding the tool
	local character = player.Character or player.CharacterAdded:Wait()
	if character and character:FindFirstChild(toolName) then
		warn("Tool already equipped: ", toolName, " for player: ", player.Name)
		return
	end

	local tool = ReplicatedStorage.Tools[toolName]:Clone()
	tool.Parent = backpack

	if toolName == "Trashcan" then
		TrashcanService.SetupTrashcan(player, tool)
	end

	if toolName == "Sword" then
		SwordService.SetupSword(player, tool)
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
