local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewportHelper = require(ReplicatedStorage.Libs.ViewportHelper)
local PetsConfig = require(ReplicatedStorage.Configs.Pets)
local GuiController = require(script.Parent.Parent.GuiController)
local PetsController = require(script.Parent.Parent.PetsController)

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
end

function Local.SetupPetStore()
	Template.Visible = false

	for _, pet in ipairs(Local.Pets) do
		local petTemplate = Template:Clone()
		petTemplate.Parent = Container
		petTemplate.Name = pet.Name
		petTemplate.Visible = true

		Local.SetupPetStoreStatus(pet, petTemplate)
		Local.SetupPetStoreViewPort(pet, petTemplate)
		Local.SetupPetStoreClickHandler(pet, petTemplate)
	end
end

function Local.SetupPetStoreStatus(pet: PetsConfig.PetInfo, template)
	local statusLabel = template:WaitForChild("Status")
	if pet.Price then
		statusLabel.Text = pet.Price
	else
		statusLabel.Text = "Free"
	end
end

function Local.SetupPetStoreViewPort(pet, template)
	local petModel = ReplicatedStorage.Pets[pet.Name]

	if not petModel then
		warn("Pet model not found in ReplicatedStorage: " .. pet.Name)
		return
	end

	local petClone = ReplicatedStorage.Pets[pet.Name]:Clone()
	local viewportFrame: ViewportFrame = template.Icon.ViewportFrame
	ViewportHelper.GenerateViewport(viewportFrame, petClone, CFrame.Angles(0, 0, 0))
end

function Local.SetupPetStoreClickHandler(pet, template)
	-- Make the frame clickable
	template.Active = true
	template.Selectable = true

	-- Use InputBegan instead of MouseButton1Click
	template.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			print("Pet clicked:", pet.Name)
			print("Description:", pet.Description or "No description")
			print("Price:", pet.Price or "Free")

			-- Print all available pet info
			for key, value in pairs(pet) do
				print(key, ":", value)
			end

			PetsController.ToggleEquippedPet(pet)
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
