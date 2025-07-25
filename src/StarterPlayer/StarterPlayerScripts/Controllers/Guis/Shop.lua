local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GetStoreRF = ReplicatedStorage:WaitForChild("GetStoreRF")

local ViewportHelper = require(ReplicatedStorage.Libs.ViewportHelper)
local TrailsConfig = require(ReplicatedStorage.Configs.Trails)
local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)
local PetsController = require(script.Parent.Parent.PetsController)
local TrailController = require(script.Parent.Parent.TrailController)
local DoubleJumpController = require(script.Parent.Parent.DoubleJumpController)
local ToolsController = require(script.Parent.Parent.ToolsController)

local Gui = GuiController.Guis.Shop
local Frame = Gui.Frame
local Container = Frame.Container
local Template = Container.Template
local OpenButton = GuiController.Guis.Left.Frame.Shop

local OPEN_BUTTON_TEXT = "Items"
local OPEN_BUTTON_IMAGE = "rbxassetid://97242152597242"

local Local = {}
local Shared = {}

-- Store active trail preview render step connections
Local.TrailPreviewConnections = {}
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

function Shared.OnStart()
	-- Setup the shop open button
	Local.SetupShopOpenButton()

	-- Seup the base gui modal handlers
	GuiController.SetupGui(Gui, OpenButton)

	-- Get the store data from the server
	Local.GetStoreInfoFromServer()

	-- Hide the template frame
	Template.Visible = false

	-- Add all the store item buttons
	Local.AddStoreItemButtons()

	-- Listen for tool equip/unequip events
	ToolsController.ToolToggled.Event:Connect(function(toolName)
		Local.RefreshButtonStatuses()
	end)

	-- Handle state updates
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateEquippedPets" then
			Local.RefreshButtonStatuses()
		end

		if action.type == "UpdateGamepass" then
			Local.EnableAbilityIfPurchased(action.gamepassId)
			Local.RefreshButtonStatuses()
		end

		if action.type == "UpdateDoubleJump" then
			Local.RefreshButtonStatuses()
		end

		if action.type == "UpdateEquippedTrails" then
			Local.RefreshButtonStatuses()
		end
	end)
end

function Local.SetupShopOpenButton()
	-- Title
	OpenButton.Title.Text = OPEN_BUTTON_TEXT

	-- Image Url
	OpenButton.Icon.Image = OPEN_BUTTON_IMAGE

	-- Image Size
	OpenButton.Icon.Size = UDim2.new(1, 0, 1, 0)
end

function Local.EnableAbilityIfPurchased(gamepassId)
	local storeInfo = Local.GetStoreInfoFromId(gamepassId)
	if not storeInfo then
		warn("No store info found for gamepass ID: ", gamepassId)
		return
	end

	if storeInfo.Name == "Double Jump" then
		DoubleJumpController.Toggle()
	end
end

function Local.RefreshButtonStatuses()
	local storeItems = Local.GetStoreItems()
	for _, item in ipairs(storeItems.Gamepasses) do
		local frame = Container:FindFirstChild(item.Name)
		if frame then
			Local.SetupItemStatus(item, frame)
		end
	end
end

function Local.AddStoreItemButtons()
	local storeItems = Local.GetStoreItems()

	-- Add Tools
	for _, item in ipairs(storeItems.Gamepasses) do
		if item.IsTool then
			Local.AddItemButton(item)
		end
	end

	-- Add Abilities
	for _, item in ipairs(storeItems.Gamepasses) do
		if item.IsAbility then
			Local.AddItemButton(item)
		end
	end

	-- Add World Pass
	for _, item in ipairs(storeItems.Gamepasses) do
		if item.IsPass then
			Local.AddItemButton(item)
		end
	end

	-- Add Products
	for _, item in ipairs(storeItems.Products) do
		if item.Name == "1000 Coins" then
			Local.AddItemButton(item)
		end
	end

	-- Add Pets
	for _, item in ipairs(storeItems.Gamepasses) do
		if item.IsPet then
			Local.AddItemButton(item)
		end
	end

	-- Add Trails
	for _, item in ipairs(storeItems.Gamepasses) do
		if item.IsTrail then
			Local.AddItemButton(item)
		end
	end
end

function Local.AddItemButton(item)
	local frame = Template:Clone()
	frame.Parent = Container
	frame.Name = item.Name
	frame.Visible = true
	frame.Template.NameLabel.Text = item.Name

	if item.IsPet then
		-- Create a viewport frame for the pet
		Local.SetupViewPort(item, frame)
	elseif item.IsTrail then
		-- Create a viewport frame for the trail preview
		Local.SetupTrailPreview(item, frame)
	elseif item.Image then
		-- create new image label instance
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "ImageLabel"
		imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		imageLabel.Position = UDim2.new(0.5, 0, 0.5, -5)
		imageLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
		imageLabel.BackgroundTransparency = 1
		imageLabel.Image = item.Image or "rbxassetid://0" -- Fallback to a default image if none is provided
		imageLabel.Parent = frame.Template.Icon
	end

	Local.SetupItemStatus(item, frame)
	Local.SetupItemClickHandler(item, frame)
end

function Local.SetupViewPort(item, frame)
	local clone
	if item.IsPet then
		local model = ReplicatedStorage.Pets[item.Name]
		if not model then
			warn("No model found for pet: ", item.Name)
			return
		end
		clone = model:Clone()
	end

	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Name = "ViewportFrame"
	viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	viewportFrame.Position = UDim2.new(0.5, 0, 0.5, -10)
	viewportFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.Parent = frame.Template.Icon
	ViewportHelper.GenerateViewport(viewportFrame, clone)
end

-- Setup a simple visual representation of a trail
function Local.SetupTrailPreview(item, frame)
	local trailName = item.Name
	local trailColorSeq = TrailsConfig.GetTrailColor(trailName)

	if not trailColorSeq then
		warn("No color sequence found for trail:", trailName)
		return
	end

	-- Create a frame to hold the trail visualization
	local trailFrame = Instance.new("Frame")
	trailFrame.Name = "TrailFrame"
	trailFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	trailFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	trailFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	trailFrame.BackgroundTransparency = 1
	trailFrame.Parent = frame.Template.Icon

	-- Create a single trail rectangle
	local trailRectangle = Instance.new("Frame")
	trailRectangle.Name = "TrailRectangle"
	trailRectangle.AnchorPoint = Vector2.new(0.5, 0.5)
	trailRectangle.Position = UDim2.new(0.5, 0, 0.5, 0)
	trailRectangle.Size = UDim2.new(0.8, 0, 0.6, 0)
	trailRectangle.BorderSizePixel = 0

	-- Round the corners
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.2, 0)
	uiCorner.Parent = trailRectangle

	-- If this is a rainbow trail, use a UIGradient
	if trailName == "Rainbow Trail" then
		trailRectangle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), -- Red
			ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 165, 0)), -- Orange
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)), -- Yellow
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)), -- Green
			ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)), -- Blue
			ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128)), -- Purple
		})
		gradient.Rotation = 0
		gradient.Parent = trailRectangle
	else
		-- For single-color trails, use the main color
		local mainColor = trailColorSeq.Keypoints[1].Value
		local endColor = trailColorSeq.Keypoints[#trailColorSeq.Keypoints].Value

		trailRectangle.BackgroundColor3 = mainColor

		-- If the trail has a gradient (start and end colors are different)
		if mainColor ~= endColor then
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, mainColor),
				ColorSequenceKeypoint.new(1, endColor),
			})
			gradient.Rotation = 0
			gradient.Parent = trailRectangle
		end
	end

	trailRectangle.Parent = trailFrame
end

function Local.SetupItemStatus(item, frame)
	local statusFrame = frame.Template:FindFirstChild("Status")
	local statusText = statusFrame:FindFirstChild("StatusText")
	local statusImage = statusFrame:FindFirstChild("StatusImage")

	local equippedItems = {}
	local state = StateController.GetState()

	if item.Name == "Double Jump" then
		local playerOwnsGamepass = state.gamepasses[tostring(item.Id)]
		equippedItems[item.Name] = playerOwnsGamepass and not state.disableDoubleJump
	end

	if item.IsTool then
		equippedItems[item.Name] = ToolsController.IsToolEquipped(item.Name)
	end

	if item.IsPet then
		equippedItems = state.equippedPets or {}
	end

	if item.IsTrail then
		equippedItems[item.Name] = state.equippedTrails[item.Name]
	end

	local isEquipped = equippedItems[item.Name] or false
	if isEquipped then
		statusImage.Visible = false
		statusText.Text = "Equipped"
		statusText.TextColor3 = Color3.fromRGB(0, 167, 25)
		statusFrame.UIStroke.Color = Color3.fromRGB(70, 255, 107)
		statusFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		frame.Template.Icon.UIStroke.Color = Color3.fromRGB(70, 255, 107)
	elseif item.Price then
		local state = StateController.GetState()
		local playerOwnsGamepass = state.gamepasses[tostring(item.Id)]
		statusText.TextColor3 = Color3.fromRGB(52, 52, 52)
		statusFrame.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		statusFrame.BackgroundColor3 = Color3.fromRGB(202, 221, 255)
		frame.Template.Icon.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		if playerOwnsGamepass then
			statusImage.Visible = false
			statusText.Text = "Owned"
		else
			statusImage.Visible = true
			statusText.Text = item.Price
		end
	else
		statusImage.Visible = false
		statusText.TextColor3 = Color3.fromRGB(52, 52, 52)
		statusFrame.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		statusFrame.BackgroundColor3 = Color3.fromRGB(202, 221, 255)
		frame.Template.Icon.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		statusText.Text = "Free"
	end
end

function Local.SetupItemClickHandler(item, frame)
	-- Variables to track touch/click position
	local inputStartPosition = nil
	local inputObject = nil
	local MAX_DRAG_DISTANCE = 2 -- Maximum pixels to consider as a tap rather than a scroll

	frame.Activated:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			Local.HandleItemSelect(item)
		end
	end)

	-- Track when input begins
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			-- Store the starting position and input object
			inputStartPosition = input.Position
			inputObject = input
		end
	end)

	-- Track when input ends
	frame.InputEnded:Connect(function(input)
		-- Only process if this is the same input object we started with
		if input == inputObject and input.UserInputType == Enum.UserInputType.Touch and inputStartPosition then
			-- Calculate how far the input moved
			local dragDistance = (input.Position - inputStartPosition).Magnitude

			-- Only consider it a tap/click if it didn't move much
			if dragDistance <= MAX_DRAG_DISTANCE then
				Local.HandleItemSelect(item)
			end

			-- Reset tracking variables
			inputStartPosition = nil
			inputObject = nil
		end
	end)
end

function Local.HandleItemSelect(item)
	local state = StateController.GetState()

	-- Is free or player already owns the pet
	local playerOwnsGamepass = state.gamepasses[tostring(item.Id)]
	if not item.Id or playerOwnsGamepass then
		if item.Name == "Double Jump" then
			-- Toggle double jump ability
			DoubleJumpController.Toggle()
		end
		if item.IsTool then
			-- Equip the tool
			ToolsController.ToggleEquip(item.Name)
			Local.RefreshButtonStatuses()
		end
		if item.IsPet then
			PetsController.ToggleEquippedPet(item)
		end
		if item.IsTrail then
			TrailController.UpdateEquippedTrail(item.Name)
		end
		return
	end

	-- Is not free and player doesn't own
	-- Prompt the purchase
	if item.IsProduct then
		-- For products, we can directly prompt purchase
		MarketPlaceService:PromptProductPurchase(Player, item.Id)
		return
	end
	if item.IsGamepass then
		-- For gamepasses, we prompt the gamepass purchase
		MarketPlaceService:PromptGamePassPurchase(Player, item.Id)
		return
	end
end

return Shared
