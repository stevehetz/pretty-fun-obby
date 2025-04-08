local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local SettingsConfig = require(ReplicatedStorage.Configs.Settings).Config
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.PlayerData.UpdateSetting.OnServerEvent:Connect(Shared.ToggleSetting)
end

function Shared.ToggleSetting(player: Player, setting: SettingsConfig.Setting)
	local doesSettingExist = SettingsConfig[setting]
	if doesSettingExist == nil then
		return
	end

	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local currentValue = state.settings[setting]
	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateSetting",
		setting = setting,
		value = not currentValue,
	}

	PlayerDataService.UpdateState(player, action)
end

return Shared
