local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ViewportHelper = require(ReplicatedStorage.Libs.ViewportHelper)
local GuiController = require(script.Parent.Parent.GuiController)

local Gui = GuiController.Guis.Pets
local Frame = Gui.Frame
local Container = Frame.Container
local Template = Container.Template
local OpenButton = GuiController.Guis.Left.Frame.Pets

local PETS = {
	"Dog",
	"Cat",
	"Fox",
	"Shark",
	"HallowsSpider",
	"Dominus Crystal",
	"Dragon",
	"Ice Dragon",
	"LilDemon",
	"Cerberus",
	"Galactic Overlord",
	"Sun Flare",
}

local Local = {}
local Shared = {}

function Shared.OnStart()
	GuiController.SetupGui(Gui, OpenButton)
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
