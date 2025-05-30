local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Remotes = ReplicatedStorage.Remotes
local GetStoreItemInfoRF = ReplicatedStorage:WaitForChild("GetStoreItemInfoRF")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)

local Gui = GuiController.Guis.Worlds
local PurchaseContainer = Gui.Frame.Main.Body.PurchaseContainer
local PurchaseBtnTemplate = PurchaseContainer.Template
local WorldListContainer = Gui.Frame.Main.Body.WorldListContainer
local WorldBtnTemplate = WorldListContainer.Template
local OpenButton = GuiController.Guis.Left.Frame.Worlds

local Local = {}
local Shared = {}

Local.TeleportPassInfoReady = false

local _teleportPassInfo = {}

function Local.GetTeleportPassInfo()
	while not Local.TeleportPassInfoReady do
		task.wait(0.1)
	end
	return _teleportPassInfo
end

function Local.GetTeleportPassInfoFromServer()
	local success, teleportPassInfo = pcall(function()
		return GetStoreItemInfoRF:InvokeServer("Teleport Pass")
	end)

	if not success then
		warn("Failed to get world pass data: ", teleportPassInfo)
		return
	end

	Local.TeleportPassInfoReady = true

	_teleportPassInfo = teleportPassInfo
end

function Shared.OnStart()
	-- Seup the base gui modal handlers
	GuiController.SetupGui(Gui, OpenButton)

	-- Get the world pass info from server
	Local.GetTeleportPassInfoFromServer()

	-- Hide the purchase item button template
	PurchaseBtnTemplate.Visible = false

	-- Hide the world button template
	WorldBtnTemplate.Visible = false

	-- Add the purchase buttons
	Local.AddPurchaseButtons()

	-- Add the world buttons
	Local.AddWorldButtons()

	-- Handle state updates
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateGamepass" then
			Local.RefreshButtonStatuses()
		end
	end)
end

function Local.RefreshButtonStatuses()
	local teleportPassInfo = Local.GetTeleportPassInfo()
	if not teleportPassInfo then
		warn("No world pass info available.")
		return
	end

	local teleportPassButton = PurchaseContainer:FindFirstChild("TeleportPass")
	Local.SetupPurchaseBtnStatus(teleportPassInfo, teleportPassButton)
end

function Local.AddPurchaseButtons()
	local teleportPassInfo = Local.GetTeleportPassInfo()
	if not teleportPassInfo then
		warn("No world pass info available.")
		return
	end

	Local.AddPurchaseButton(teleportPassInfo)
end

function Local.AddWorldButtons()
	local worlds = WorldsConfig.GetAllWorlds()
	if not worlds then
		warn("No worlds available.")
		return
	end

	for worldName, worldData in pairs(worlds) do
		local button = WorldBtnTemplate:Clone()
		button.Name = worldName
		button.Visible = true
		button.Text = worldData.DisplayName
		button.Parent = WorldListContainer

		worldData.IsWorldButton = true

		Local.SetupItemClickHandler(worldData, button)
	end
end

function Local.AddPurchaseButton(item)
	local button = PurchaseBtnTemplate:Clone()
	button.Name = item.Name:gsub(" ", "")
	button.Visible = true
	button.NameLabel.Text = item.Name
	button.Parent = PurchaseContainer
	Local.SetupPurchaseBtnStatus(item, button)
	Local.SetupItemClickHandler(item, button)
end

function Local.SetupPurchaseBtnStatus(item, button)
	local statusFrame = button:FindFirstChild("Status")
	local statusText = statusFrame:FindFirstChild("StatusText")
	local statusImage = statusFrame:FindFirstChild("StatusImage")

	local state = StateController.GetState()
	local playerOwnsGamepass = state.gamepasses[tostring(item.Id)]
	statusText.TextColor3 = Color3.fromRGB(52, 52, 52)
	statusFrame.UIStroke.Color = Color3.fromRGB(21, 97, 159)
	statusFrame.BackgroundColor3 = Color3.fromRGB(202, 221, 255)
	button.Icon.UIStroke.Color = Color3.fromRGB(21, 97, 159)
	if playerOwnsGamepass then
		statusImage.Visible = false
		statusText.Text = "Owned"
	else
		statusImage.Visible = true
		statusText.Text = item.Price
	end
end

function Local.SetupItemClickHandler(item, button)
	-- Variables to track touch/click position
	local inputStartPosition = nil
	local inputObject = nil
	local MAX_DRAG_DISTANCE = 2 -- Maximum pixels to consider as a tap rather than a scroll

	button.Activated:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			Local.HandleItemSelect(item)
		end
	end)

	-- Track when input begins
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			-- Store the starting position and input object
			inputStartPosition = input.Position
			inputObject = input
		end
	end)

	-- Track when input ends
	button.InputEnded:Connect(function(input)
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

	if item.Name == "Teleport Pass" then
		local playerOwnsGamepass = state.gamepasses[tostring(item.Id)]
		if not playerOwnsGamepass then
			-- Prompt the purchase for the teleport pass
			MarketPlaceService:PromptGamePassPurchase(Player, item.Id)
		end
		return
	end

	if item.IsWorldButton then
		local teleportPassInfo = Local.GetTeleportPassInfo()

		if WorldsConfig.GetCurrentWorldName() == item.Name then
			-- Already in the current world, no need to teleport
			print("WorldsController - Already in world: " .. item.DisplayName)
			return
		end

		local playerOwnsGamepass = state.gamepasses[tostring(teleportPassInfo.Id)]
		if not playerOwnsGamepass and item.Name ~= "World1" then
			-- Prompt the purchase for the teleport pass
			MarketPlaceService:PromptGamePassPurchase(Player, teleportPassInfo.Id)
			return
		end

		-- Close the dialog beofre teleporting
		GuiController.ToggleGui(Gui)
		-- Do the teleport
		Remotes.Teleport:FireServer(item.Name)
	end
end

return Shared
