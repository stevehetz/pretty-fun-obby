local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local TestService = require(script.Parent.TestService)
local TrashcanService = require(script.Parent.TrashcanService)
local SwordService = require(script.Parent.SwordService)

local Local = {}
local Shared = {}

PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
	Local.GiveTools(player)
	print("Profile loaded for player: ", player.Name)
	player.CharacterAdded:Connect(function()
		print("Character added for player: ", player.Name)
		Local.GiveTools(player)
	end)
end)

function Local.GiveTools(player: Player)
	print("Giving tools to player: ", player.Name)
	Shared.GiveTool(player, "Gravity Coil", 1157798560)
	Shared.GiveTool(player, "Speed Coil", 1157906298)
	Shared.GiveTool(player, "Sword", 1255668315)

	-- Check if player has purchased a trashcan
	local state = PlayerDataService.GetState(player)
	if state and state.hasTrashcan then
		print("Giving trashcan to player: ", player.Name)
		Shared.GiveTool(player, "Trashcan")
	elseif TestService.IsDev() then
		-- Shared.GiveTool(player, "Trashcan")
		-- Shared.GiveTool(player, "Sword")
	elseif TestService.IsTester() then
		print("Giving trashcan and sword to tester: ", player.Name)
		Shared.GiveTool(player, "Sword")
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

	print("Has gamepass: ", gamepassId, " for tool: ", toolName, " for player: ", player.Name)

	-- Not a gamepass tool or player owns the gamepass
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		warn("Backpack not found for player: ", player.Name)
		return
	end

	-- Make sure player doesn't ahve tool in backpack
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

	local trashcan = ReplicatedStorage.Tools[toolName]:Clone()
	trashcan.Parent = backpack

	if toolName == "Trashcan" then
		print("Setting up trashcan for player: ", player.Name)
		TrashcanService.SetupTrashcan(player, trashcan)
	end

	if toolName == "Sword" then
		print("Setting up sword for player: ", player.Name)
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
