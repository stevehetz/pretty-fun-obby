local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateController = require(script.Parent.StateController)
local SettingsConfig = require(ReplicatedStorage.Configs.Settings)
local Remotes = ReplicatedStorage.Remotes.PlayerData

local Local = {}
local Shared = {}

Shared.UpdateState = Instance.new("BindableEvent")

function Shared.OnStart()
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
			Local.UpdateSetting(action.setting, action.value)
	end)
end

function Local.UpdateSetting(setting: SettingsConfig.Setting, value: boolean)
	-- Handle Music / etc
end

function Shared.ToggleSetting(setting: SettingsConfig.Setting)
	Remotes.UpdateSetting:FireServer(setting)
end

return Shared