local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiController = require(script.Parent.Parent.GuiController)
local SettingsController = require(script.Parent.Parent.SettingsController)
local StateController = require(script.Parent.Parent.StateController)
local SettingsConfig = require(ReplicatedStorage.Configs.Settings)
local SoundsConfig = require(ReplicatedStorage.Configs.Sounds)

local Gui = GuiController.Guis.Setting
local Frame = Gui.Frame
local Container = Frame.Container
local OpenButton = GuiController.Guis.Top.Frame.Settings

local ON_COLOR = Color3.fromRGB(61, 219, 67)
local OFF_COLOR = Color3.fromRGB(232, 70, 70)

local Local = {}
local Shared = {}

function Shared.OnStart()
	GuiController.SetupGui(Gui, OpenButton)

	Local.GenerateSettings()

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
	
	if Gui.Enabled then
		local sound = if isEnabled then "Confirm" else "Error"
		SoundsConfig.PlaySound(sound)
	end
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
