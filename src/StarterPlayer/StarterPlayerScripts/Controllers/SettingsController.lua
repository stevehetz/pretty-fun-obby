local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local StateController = require(script.Parent.StateController)
local SettingsConfig = require(ReplicatedStorage.Configs.Settings)
local SoundsConfig = require(ReplicatedStorage.Configs.Sounds)
local Remotes = ReplicatedStorage.Remotes.PlayerData

local Local = {}
local Shared = {}

function Shared.OnStart()
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateSetting" then
			Local.UpdateSetting(action.setting, action.value)
		end
	end)

	local isMusicEnabled = SettingsConfig.GetSettingValue(StateController.GetState(), "Music")
	Local.PlayMusic(isMusicEnabled)

	local isSoundEffectsEnabled = SettingsConfig.GetSettingValue(StateController.GetState(), "Sound Effects")
	Local.UpdateSetting("Sound Effects", isSoundEffectsEnabled)
end

function Local.UpdateSetting(setting: SettingsConfig.Setting, enabled: boolean)
	local isMusic = setting == "Music"
	if isMusic then
		Local.PlayMusic(enabled)
	end

	local isSoundEffects = setting == "Sound Effects"
	if isSoundEffects then
		for _, sound: Sound in ReplicatedStorage.Sounds:GetChildren() do
			if sound:IsA("Sound") then
				if sound.Name == "Dink" then
					-- Trashcan sound is always enabled
					sound.Volume = if enabled then 0.5 else 0
				else
					-- Other sounds are controlled by the setting
					sound.Volume = if enabled then 0.15 else 0
				end
			end
		end

		if enabled then
			SoundsConfig.PlaySound("Confirm")
		end
	end
end

function Shared.ToggleSetting(setting: SettingsConfig.Setting)
	Remotes.UpdateSetting:FireServer(setting)
end

function Local.PlayMusic(shouldPlay: boolean)
	local song = Workspace:FindFirstChild("Music")
	if not song then
		song = SoundsConfig.GetSound("Music")
		song.Looped = true
		song.Volume = 0.25
		song.Parent = Workspace
	end

	if shouldPlay then
		song:Play()
	else
		song:Stop()
	end
end

return Shared
