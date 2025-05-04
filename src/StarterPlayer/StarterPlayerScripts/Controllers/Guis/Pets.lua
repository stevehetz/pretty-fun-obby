local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local ViewportHelper = require(ReplicatedStorage.Libs.ViewportHelper)
local PetsConfig = require(ReplicatedStorage.Configs.Pets)
local StoreConfig = require(ReplicatedStorage.Configs.Store)
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

Local.Pets = PetsConfig.GetPets()

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

function Local.SetupPetStore()
	Template.Visible = false
	local equippedPets = StateController.GetState().equippedPets

	for _, pet in ipairs(Local.Pets) do
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
	for _, pet in ipairs(Local.Pets) do
		local petFrame = Container:FindFirstChild(pet.Name)
		if not petFrame then
			continue
		end

		Local.SetupPetStoreStatus(pet, petFrame, equippedPets)
	end
end

function Local.SetupPetStoreStatus(pet: PetsConfig.PetInfo, petFrame, equippedPets)
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
		local owned = StoreConfig.DoesPlayerOwnGamepass(state, pet.GamePassId)
		statusText.TextColor3 = Color3.fromRGB(52, 52, 52)
		statusFrame.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		statusFrame.BackgroundColor3 = Color3.fromRGB(202, 221, 255)
		petFrame.Icon.UIStroke.Color = Color3.fromRGB(21, 97, 159)
		if owned then
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
	petFrame.Active = true
	petFrame.Selectable = true

	-- Use InputBegan instead of MouseButton1Click
	petFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local state = StateController.GetState()

			-- Is free or player already owns the pet
			if not pet.GamePassId or StoreConfig.DoesPlayerOwnGamepass(state, pet.GamePassId) then
				PetsController.ToggleEquippedPet(pet)
				return
			end

			-- Is not free and player doesn't own the pet
			-- Prompt the purchase
			MarketPlaceService:PromptGamePassPurchase(Player, pet.GamePassId)
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
