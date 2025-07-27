local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)
local ToolsController = require(script.Parent.Parent.ToolsController)
local PetsController = require(script.Parent.Parent.PetsController)
local TrailController = require(script.Parent.Parent.TrailController)

local UnequipAllBtn = GuiController.Guis.Left.Frame.UnequipAll

local Local = {}
local Shared = {}

function Shared.OnStart()
	UnequipAllBtn.MouseButton1Click:Connect(function()
		Local.UnequipAll()
	end)

	UnequipAllBtn.Visible = false

	-- Wait for state to be available before checking equipment status
	task.spawn(function()
		local state = StateController.GetState()
		task.wait(1)
		Local.UpdateButtonVisibility()
	end)

	-- Listen for state changes to update button visibility
	StateController.UpdateState.Event:Connect(function(action)
		Local.UpdateButtonVisibility()
	end)

	-- Update visibility when character changes
	Player.CharacterAdded:Connect(function(char)
		Local.CharacterEventListener(char)
	end)

	-- If character already exists, set up the same listeners
	if Player.Character then
		Local.CharacterEventListener(Player.Character)
	end
end

function Local.CharacterEventListener(char)
	-- Listen for when tools are added to the character
	char.ChildAdded:Connect(function(child)
		Local.UpdateButtonVisibility()
	end)

	-- Listen for when tools are removed from the character
	char.ChildRemoved:Connect(function(child)
		Local.UpdateButtonVisibility()
	end)
end

-- Function to check if any tool, pet, or trail is equipped
function Local.IsAnyItemEquipped()
	local state = StateController.GetState()
	local character = Player.Character

	-- Check if any tool is equipped
	if character then
		-- Check if any tool is equipped directly using character's children
		for _, item in pairs(character:GetChildren()) do
			if item:IsA("Tool") then
				return true
			end
		end
	end

	-- Check if any pet is equipped
	if state and state.equippedPets and next(state.equippedPets) then
		return true
	end

	-- Check if any trail is equipped
	if state and state.equippedTrails and next(state.equippedTrails) then
		return true
	end

	return false
end

-- Function to unequip all tools, pets, and trails
function Local.UnequipAll()
	-- Get all equipped tools directly from character
	local character = Player.Character
	if character then
		-- Find all tools directly in the character
		local equippedTools = {}
		for _, item in pairs(character:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(equippedTools, item)
			end
		end

		-- Unequip each tool using ToolsController
		for _, tool in ipairs(equippedTools) do
			ToolsController.ToggleEquip(tool.Name)
		end
	end

	-- Get state to check equipped pets and trails
	local state = StateController.GetState()

	-- Unequip pet if any is equipped
	if state and state.equippedPets and next(state.equippedPets) then
		for petName, _ in pairs(state.equippedPets) do
			-- Create a mock item object similar to what Shop.lua would pass
			local petItem = {
				Name = petName,
				IsPet = true,
			}
			PetsController.ToggleEquippedPet(petItem)
			break -- Only one pet can be equipped at a time
		end
	end

	-- Unequip trail if any is equipped
	if state and state.equippedTrails and next(state.equippedTrails) then
		for trailName, _ in pairs(state.equippedTrails) do
			TrailController.UpdateEquippedTrail(trailName)
			break -- Only one trail can be equipped at a time
		end
	end
end

-- Function to update button visibility
function Local.UpdateButtonVisibility()
	local isEquipped = Local.IsAnyItemEquipped()

	if UnequipAllBtn then
		UnequipAllBtn.Visible = isEquipped
	end
end

return Shared
