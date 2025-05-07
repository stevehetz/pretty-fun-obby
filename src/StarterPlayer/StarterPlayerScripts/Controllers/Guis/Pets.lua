local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GetStoreRF = ReplicatedStorage:WaitForChild("GetStoreRF")

local ViewportHelper = require(ReplicatedStorage.Libs.ViewportHelper)
local GuiController = require(script.Parent.Parent.GuiController)
local PetsController = require(script.Parent.Parent.PetsController)
local StateController = require(script.Parent.Parent.StateController)

local Gui = GuiController.Guis.Pets
local Frame = Gui.Frame
local Container = Frame.Container
local Template = Container.Template
local OpenButton = GuiController.Guis.Left.Frame.Pets

local Local = {}
local Shared = {}

local FREE_PETS = {
	{
		Name = "Dog",
	},
	{
		Name = "Cat",
	},
}

function Shared.OnStart()
	GuiController.SetupGui(Gui, OpenButton)
	Local.AddOpenButtonImage()
	Local.SetupPetStore()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateEquippedPets" then
			Local.RefreshStatus()
		end
	end)
end

function Local.GetPets()
	local pets = {}
	local success, store = pcall(function()
		return GetStoreRF:InvokeServer()
	end)

	if not success then
		warn("Failed to get store data: ", store)
		return
	end

	for _, freePet in ipairs(FREE_PETS) do
		local petInfo = {
			Name = freePet.Name,
			Id = nil,
			Price = nil,
			Image = nil,
			IsPet = true,
		}
		table.insert(pets, petInfo)
	end

	for _, gamepassInfo in ipairs(store.Gamepasses) do
		if gamepassInfo.IsPet then
			table.insert(pets, gamepassInfo)
		end
	end

	return pets
end

function Local.SetupPetStore()
	Template.Visible = false
	local equippedPets = StateController.GetState().equippedPets

	local pets = Local.GetPets()

	for _, pet in ipairs(pets) do
		local petFrame = Template:Clone()
		petFrame.Parent = Container
		petFrame.Name = pet.Name
		petFrame.Visible = true
		petFrame.NameLabel.Text = pet.Name

		Local.SetupPetStoreStatus(pet, petFrame, equippedPets)
		Local.SetupPetStoreViewPort(pet, petFrame)
		Local.SetupPetStoreClickHandler(pet, petFrame)
	end
end

function Local.RefreshStatus()
	local equippedPets = StateController.GetState().equippedPets
	local pets = Local.GetPets()
	for _, pet in ipairs(pets) do
		local petFrame = Container:FindFirstChild(pet.Name)
		if not petFrame then
			continue
		end

		Local.SetupPetStoreStatus(pet, petFrame, equippedPets)
	end
end

function Local.SetupPetStoreStatus(pet, petFrame, equippedPets)
	local statusFrame = petFrame:FindFirstChild("Status")
	local statusText = statusFrame:FindFirstChild("StatusText")
	local statusImage = statusFrame:FindFirstChild("StatusImage")

	local isEquipped = equippedPets[pet.Name] or false
	if isEquipped then
		statusImage.Visible = false
		statusText.Text = "Equipped"
		statusText.TextColor3 = Color3.fromRGB(0, 167, 25)
		statusFrame.UIStroke.Color = Color3.fromRGB(70, 255, 107)
		statusFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		petFrame.Icon.UIStroke.Color = Color3.fromRGB(70, 255, 107)
	elseif pet.Price then
		local state = StateController.GetState()
		local playerOwnsGamepass = state.gamepasses[tostring(pet.Id)]
		statusText.TextColor3 = Color3.fromRGB(52, 52, 52)
		statusFrame.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		statusFrame.BackgroundColor3 = Color3.fromRGB(202, 221, 255)
		petFrame.Icon.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		if playerOwnsGamepass then
			statusImage.Visible = false
			statusText.Text = "Owned"
		else
			statusImage.Visible = true
			statusText.Text = pet.Price
		end
	else
		statusImage.Visible = false
		statusText.TextColor3 = Color3.fromRGB(52, 52, 52)
		statusFrame.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		statusFrame.BackgroundColor3 = Color3.fromRGB(202, 221, 255)
		petFrame.Icon.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		statusText.Text = "Free"
	end
end

function Local.SetupPetStoreViewPort(pet, petFrame)
	local petModel = ReplicatedStorage.Pets[pet.Name]

	if not petModel then
		warn("Pet model not found in ReplicatedStorage: " .. pet.Name)
		return
	end

	local petClone = ReplicatedStorage.Pets[pet.Name]:Clone()
	local viewportFrame: ViewportFrame = petFrame.Icon.ViewportFrame
	ViewportHelper.GenerateViewport(viewportFrame, petClone, CFrame.Angles(0, 0, 0))
end

function Local.SetupPetStoreClickHandler(pet, petFrame)
	-- Make the frame clickable
	-- petFrame.Active = true
	-- petFrame.Selectable = true

	-- Variables to track touch/click position
	local inputStartPosition = nil
	local inputObject = nil
	local MAX_DRAG_DISTANCE = 2 -- Maximum pixels to consider as a tap rather than a scroll

	-- Track when input begins
	petFrame.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			-- Store the starting position and input object
			inputStartPosition = input.Position
			inputObject = input
		end
	end)

	-- Track when input ends
	petFrame.InputEnded:Connect(function(input)
		-- Only process if this is the same input object we started with
		if input == inputObject and inputStartPosition then
			-- Calculate how far the input moved
			local dragDistance = (input.Position - inputStartPosition).Magnitude

			-- Only consider it a tap/click if it didn't move much
			if dragDistance <= MAX_DRAG_DISTANCE then
				local state = StateController.GetState()

				-- Is free or player already owns the pet
				local playerOwnsGamepass = state.gamepasses[tostring(pet.Id)]
				if not pet.Id or playerOwnsGamepass then
					PetsController.ToggleEquippedPet(pet)
					return
				end

				-- Is not free and player doesn't own the pet
				-- Prompt the purchase
				MarketPlaceService:PromptGamePassPurchase(Player, pet.Id)
			end

			-- Reset tracking variables
			inputStartPosition = nil
			inputObject = nil
		end
	end)
end

function Local.AddOpenButtonImage()
	local PET = "Ice Dragon"
	local petModel = ReplicatedStorage.Pets[PET]
	if not petModel then
		warn("Pet model not found in ReplicatedStorage: " .. PET)
		return
	end

	local petClone = petModel:Clone()
	local viewportFrame: ViewportFrame = OpenButton.ViewportFrame
	ViewportHelper.GenerateViewport(viewportFrame, petClone, CFrame.Angles(0, 0, 0))
end

return Shared
