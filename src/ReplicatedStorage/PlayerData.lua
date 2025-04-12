local SettingsConfig = require(script.Parent.Configs.Settings)

export type PlayerData = {
	stage: number,
	deaths: number,
	rebirths: number,
	settings: { [SettingsConfig.Setting]: boolean },
	skips: {
		amount: number,
		next: number,
	},
	vip: boolean
}

local SettingsData = {}
for setting, value in SettingsConfig.Config do
	SettingsData[setting] = value
end

local DEFAULT_PLAYER_DATA: PlayerData = {
	stage = 1,
	deaths = 0,
	rebirths = 0,
	settings = SettingsData,
	skips = {
		amount = 0,
		next = 0,
	},
	vip = false
}

local Shared = {}

Shared.DEFAULT_PLAYER_DATA = DEFAULT_PLAYER_DATA

return Shared
