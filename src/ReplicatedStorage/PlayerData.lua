local SettingsConfig = require(script.Parent.Configs.Settings)
local StoreConfig = require(script.Parent.Configs.Store)

export type PlayerData = {
	stage: number,
	deaths: number,
	settings: { [SettingsConfig.Setting]: boolean },
	skips: {
		amount: number,
	},
	vip: boolean,
	gamepasses: {
		[string]: boolean,
	},
	finishes: number,
}

local SettingsData = {}
for setting, value in SettingsConfig.Config do
	SettingsData[setting] = value
end

local GamepassesData = {}
for _, gamepassInfo in StoreConfig.Store.Gamepasses do
	GamepassesData[tostring(gamepassInfo.Id)] = false
end

local DEFAULT_PLAYER_DATA: PlayerData = {
	stage = 0,
	deaths = 0,
	settings = SettingsData,
	skips = {
		amount = 0,
	},
	vip = false,
	gamepasses = GamepassesData,
	finishes = 0,
}

local Shared = {}

Shared.DEFAULT_PLAYER_DATA = DEFAULT_PLAYER_DATA

return Shared
