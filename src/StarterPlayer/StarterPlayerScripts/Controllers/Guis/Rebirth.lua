local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiController = require(script.Parent.Parent.GuiController)
local Remotes = ReplicatedStorage.Remotes

local Gui = GuiController.Guis.Rebirth
local Frame = Gui.Frame
local UseButton = Frame.Use
local OpenButton = GuiController.Guis.Top.Frame.Rebirth

local Local = {}
local Shared = {}

function Shared.OnStart()
	GuiController.SetupGui(Gui, OpenButton)

	UseButton.MouseButton1Click:Connect(function()
		GuiController.ToggleGui(Gui)
		Remotes.Rebirth:FireServer()
	end)
end

return Shared
