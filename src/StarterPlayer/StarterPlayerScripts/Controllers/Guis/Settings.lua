local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiController = require(script.Parent.Parent.GuiController)
local SettingsController = require(script.Parent.Parent.SettingsController)
local StateController = require(script.Parent.Parent.StateController)
local SettingsConfig = require(ReplicatedStorage.Configs.Settings)

local Gui = GuiController.Guis.Setting
local Frame = Gui.Frame
local Container = Frame.Container
local OpenButton = GuiController.Guis.Right.Frame.Settings
local ExitButton = Frame.Exit

local ON_COLOR = Color3.fromRGB(61, 219, 67)
local OFF_COLOR = Color3.fromRGB(232, 70, 70)

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.GenerateSettings()

	OpenButton.MouseButton1Click:Connect(function()
		Gui.Enabled = not Gui.Enabled
		GuiController.ToggleBlurEffect(Gui.Enabled)
	end)
	ExitButton.MouseButton1Click:Connect(function()
		Gui.Enabled = false
		GuiController.ToggleBlurEffect(false)
	end)

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateSetting" then
			Local.ToggleSetting(action.setting)
		end
	end)

	Container.Template.Visible = false
end

function Local.ToggleSetting(setting: SettingsConfig.Setting)
	local frame = Container:FindFirstChild(setting)
	if not frame then
		return
	end

	local isEnabled = SettingsConfig.GetSettingValue(StateController.GetState(), setting)
	frame.Toggle.BackgroundColor3 = if isEnabled then ON_COLOR else OFF_COLOR
end

function Local.GenerateSettings()
	for setting, value in SettingsConfig.Config do
		local clone = Container.Template:Clone()
		clone.Parent = Container
		clone.Name = setting
		clone.Visible = true

		clone.Setting.Text = setting

		clone.Toggle.MouseButton1Click:Connect(function()
			SettingsController.ToggleSetting(setting)
		end)

		Local.ToggleSetting(setting)
	end
end

return Shared
