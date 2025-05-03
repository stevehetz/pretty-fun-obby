local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewportHelper = require(ReplicatedStorage.Libs.ViewportHelper)
local GuiController = require(script.Parent.Parent.GuiController)

local Gui = GuiController.Guis.Pets
local Frame = Gui.Frame
local Container = Frame.Container
local Template = Container.Template

local PETS = {
	"Dog",
	"Cat",
	"LilDemon",
	"HallowsSpider",
	"Cerberus",
}

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.SetupPets()
end

function Local.SetupPets()
	for _, petName in ipairs(PETS) do
		local petTemplate = Template:Clone()
		petTemplate.Parent = Container
		petTemplate.Name = petName
		petTemplate.Visible = true

		local petModel = ReplicatedStorage.Pets[petName]

		if not petModel then
			warn("Pet model not found in ReplicatedStorage: " .. petName)
			continue
		end

		local petClone = ReplicatedStorage.Pets[petName]:Clone()
		local viewportFrame: ViewportFrame = petTemplate.Icon.ViewportFrame
		ViewportHelper.GenerateViewport(viewportFrame, petClone, CFrame.Angles(0, 0, 0))
	end
end

return Shared
