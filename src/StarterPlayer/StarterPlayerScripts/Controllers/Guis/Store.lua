local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GetStoreRF = ReplicatedStorage:WaitForChild("GetStoreRF")

local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)
local DoubleJumpController = require(script.Parent.Parent.DoubleJumpController)

local Gui = GuiController.Guis.Left
local Frame = Gui.Frame

local Local = {}
local Shared = {}

Local.StoreItemInfoReady = false

local _storeItems = {}

function Local.GetStoreInfoFromServer()
	local success, store = pcall(function()
		return GetStoreRF:InvokeServer()
	end)

	if not success then
		warn("Failed to get store data: ", store)
		return
	end

	Local.StoreItemInfoReady = true

	_storeItems = store
end

function Local.GetStoreItems()
	while not Local.StoreItemInfoReady do
		task.wait(0.1)
	end
	return _storeItems
end

function Shared.OnStart()
	-- Get the store data from the server
	Local.GetStoreInfoFromServer()

	-- Setup each button using store data
	Local.SetupAllButtons()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		local isGamepass = action.type == "UpdateGamepass"
		local isDoubleJumpToggle = action.type == "UpdateDoubleJump"

		local storeInfo = nil

		if isGamepass then
			storeInfo = Local.GetStoreInfoFromId(action.gamepassId)
		elseif isDoubleJumpToggle then
			storeInfo = Local.GetStoreInfoFromName("Double Jump")
		else
			return
		end

		if not storeInfo then
			print("Store info not found")
			return
		end

		-- Handle non double jump state change
		-- This means someone bought a gamepass that was not double jump
		-- Basically just need to toggle visibility of the button
		if storeInfo.Name ~= "Double Jump" then
			Local.SetButtonVisibility(storeInfo.Name, action.value)
			return
		end

		-- Handle double jump state change
		-- This means they bough double jump or toggled it
		-- Click handler and UI state needs to be updated
		if storeInfo.Name == "Double Jump" then
			Local.UpdateDoubleJumpButton()
			return
		end
	end)
end

-- Iterate through and setup all buttons
function Local.SetupAllButtons()
	for _, info in Local.GetStoreItems().Gamepasses do
		-- Return if we dont have the info
		if not info or not info.Name then
			return
		end

		-- Make sure button with same name exists
		local button: TextButton = Frame:FindFirstChild(info.Name:gsub(" ", ""))
		if not button then
			return
		end

		-- Set image on button from one from server (marketplace)
		button.Icon.Image = info.Image

		if info.Name ~= "Double Jump" then
			-- Setup button for gamepass
			Local.SetupButton(button, info)
		else
			-- Special case for double jump
			Local.SetupDoubleJumpButton(button, info)
		end
	end
end

-- --------------------HELPERS--------------------

-- Get the get store info from name
function Local.GetStoreInfoFromName(name: string)
	local storeInfo = nil
	for _, info in Local.GetStoreItems().Gamepasses do
		if info.Name == name then
			storeInfo = info
			break
		end
	end

	return storeInfo
end

-- Get the get store info from id
function Local.GetStoreInfoFromId(id: number)
	local storeInfo = nil
	for _, info in Local.GetStoreItems().Gamepasses do
		if info.Id == id then
			storeInfo = info
			break
		end
	end

	return storeInfo
end

-- --------------------NON DOUBLE JUMP BUTTONS--------------------

-- Setup gamepass button - all but double jump
function Local.SetupButton(button, info)
	local state = StateController.GetState()
	if not state then
		return
	end

	local ownsGamepass = state.gamepasses[tostring(info.Id)] or false

	button.MouseButton1Click:Connect(function()
		if not ownsGamepass then
			MarketPlaceService:PromptGamePassPurchase(Player, info.Id)
		end
	end)

	Local.SetButtonVisibility(info.Name, ownsGamepass)
end

-- Setup gamepass button visibility - all but double jump
function Local.SetButtonVisibility(name: string, isPurchased: boolean)
	local button: TextButton = Frame:FindFirstChild(name:gsub(" ", ""))

	if button then
		button.Visible = not isPurchased
	end
end

-- --------------------DOUBLE JUMP BUTTON-------------------

function Local.SetupDoubleJumpButton(button, info)
	-- Setup double jump click handler
	Local.SetupDoubleJumpClickHandler(button, info)

	-- Initialize button appearance based on current state
	Local.UpdateDoubleJumpButton()
end

-- Setup double jump button click handler
function Local.SetupDoubleJumpClickHandler(button, info)
	button.MouseButton1Click:Connect(function()
		local state = StateController.GetState()
		if not state then
			return
		end

		local ownsGamepass = state.gamepasses[tostring(info.Id)] or false

		if not ownsGamepass then
			-- Doesn't own the gamepass, prompt purchase
			MarketPlaceService:PromptGamePassPurchase(Player, info.Id)
		else
			-- Owns gamepass, toggle double jump on/off
			DoubleJumpController.Toggle()
		end
	end)
end

-- Update the Double Jump button appearance based on enabled/disabled state
function Local.UpdateDoubleJumpButton()
	-- Grab the current state
	local state = StateController.GetState()
	if not state then
		return
	end

	-- Get double jump id
	local storeInfo = Local.GetStoreInfoFromName("Double Jump")
	if not storeInfo then
		return
	end
	local DoubleJumpId = storeInfo.Id

	-- Check if owns double jump gamepass
	local playerOwnsGamepass = state.gamepasses[tostring(DoubleJumpId)] or false

	-- Check if double jump is disabled
	local doubleJumpDisabled = state.disableDoubleJump

	-- Should button be enabled?
	local isEnabled = playerOwnsGamepass and not doubleJumpDisabled

	-- Update button appearance based on enabled/disabled state
	local doubleJumpButton = Frame:FindFirstChild("DoubleJump")
	if doubleJumpButton then
		local title = doubleJumpButton:FindFirstChild("Title")
		local status = doubleJumpButton:FindFirstChild("Status")
		if title then
			title.TextColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
		end
		if status then
			status.TextColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
			status.Text = isEnabled and "On" or "Off"
		end
	end
end

return Shared
