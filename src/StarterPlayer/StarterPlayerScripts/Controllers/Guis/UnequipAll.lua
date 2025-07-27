local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Remotes = ReplicatedStorage.Remotes

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)
local ToolsController = require(script.Parent.Parent.ToolsController)
local PetsController = require(script.Parent.Parent.PetsController)
local TrailController = require(script.Parent.Parent.TrailController)
local SoundController = require(script.Parent.Parent.SoundController)

local UnequipAllBtn = GuiController.Guis.Left.Frame.UnequipAll

local Local = {}
local Shared = {}

-- Function to check if any tool, pet, or trail is equipped
function Local.IsAnyItemEquipped()
	local state = StateController.GetState()
	local character = Player.Character

	-- Debug print
	print("Checking if any item is equipped")

	-- Check if any tool is equipped
	if character then
		-- Check if any tool is equipped directly using character's children
		for _, item in pairs(character:GetChildren()) do
			if item:IsA("Tool") then
				print("Tool equipped:", item.Name)
				return true
			end
		end
	end

	-- Check if any pet is equipped
	if state and state.equippedPets and next(state.equippedPets) then
		print("Pet equipped:", next(state.equippedPets))
		return true
	end

	-- Check if any trail is equipped
	if state and state.equippedTrails and next(state.equippedTrails) then
		print("Trail equipped:", next(state.equippedTrails))
		return true
	end

	print("No items equipped")
	return false
end

-- Function to unequip all tools, pets, and trails
function Local.UnequipAll()
	-- Play sound effect
	-- SoundController.PlaySound("Menu-Click")

	-- Get all equipped tools directly from character
	local character = Player.Character
	if character then
		print("Unequipping tools from character")

		-- Find all tools directly in the character
		local equippedTools = {}
		for _, item in pairs(character:GetChildren()) do
			if item:IsA("Tool") then
				print("Found equipped tool:", item.Name)
				table.insert(equippedTools, item)
			end
		end

		-- Unequip each tool
		if #equippedTools > 0 then
			print("Unequipping", #equippedTools, "tools")

			-- Method 1: Use Humanoid:UnequipTools() directly
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				print("Using Humanoid:UnequipTools()")
				humanoid:UnequipTools()
			else
				print("Humanoid not found, using alternative method")

				-- Method 2: Move each tool back to backpack
				local backpack = Player:FindFirstChild("Backpack")
				if backpack then
					for _, tool in ipairs(equippedTools) do
						print("Moving tool to backpack:", tool.Name)
						tool.Parent = backpack
					end
				else
					print("Backpack not found")
				end
			end
		else
			print("No tools to unequip")
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
	print("UpdateButtonVisibility - isEquipped:", isEquipped)

	-- Make sure the button exists
	if UnequipAllBtn then
		UnequipAllBtn.Visible = isEquipped
		print("Set UnequipAllBtn.Visible to", isEquipped)
	else
		warn("UnequipAllBtn is nil!")
	end
end

function Shared.OnStart()
	print("UnequipAll OnStart")

	-- Make sure the button exists and set it up
	if not UnequipAllBtn then
		warn("UnequipAllBtn not found!")
		return
	end

	-- Set up button click event
	UnequipAllBtn.MouseButton1Click:Connect(function()
		print("UnequipAll button clicked")
		Local.UnequipAll()
	end)

	-- Set initial visibility (hidden by default until we confirm something is equipped)
	UnequipAllBtn.Visible = false

	-- Wait for state to be available before checking equipment status
	task.spawn(function()
		print("Waiting for state to be available")
		local state = StateController.GetState() -- This will wait until state is available
		print("State is available, waiting additional time")
		task.wait(1) -- Additional wait to ensure everything is loaded
		print("Updating button visibility after initial wait")
		Local.UpdateButtonVisibility()
	end)

	-- Listen for state changes to update button visibility
	StateController.UpdateState.Event:Connect(function(action)
		print("State updated:", action.type)
		-- Update for any state change that might affect equipment
		Local.UpdateButtonVisibility()
	end)

	-- Listen for tool equip/unequip events
	ToolsController.ToolToggled.Event:Connect(function(toolName)
		print("Tool toggled:", toolName)
		Local.UpdateButtonVisibility()
	end)

	-- Update visibility when character changes
	Player.CharacterAdded:Connect(function(char)
		print("Character added")

		-- Listen for when tools are added to the character
		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				print("Tool added to character:", child.Name)
				Local.UpdateButtonVisibility()
			end
		end)

		-- Listen for when tools are removed from the character
		char.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				print("Tool removed from character:", child.Name)
				task.wait(0.1) -- Small delay to ensure state is updated
				Local.UpdateButtonVisibility()
			end
		end)

		task.wait(1) -- Wait for character to fully load
		Local.UpdateButtonVisibility()
	end)

	-- If character already exists, set up the same listeners
	if Player.Character then
		print("Character already exists, setting up listeners")
		local char = Player.Character

		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				print("Tool added to existing character:", child.Name)
				Local.UpdateButtonVisibility()
			end
		end)

		char.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				print("Tool removed from existing character:", child.Name)
				task.wait(0.1) -- Small delay to ensure state is updated
				Local.UpdateButtonVisibility()
			end
		end)
	end
end

return Shared
