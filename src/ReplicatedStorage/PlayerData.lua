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
	teleporting: {
		world: string,
	},
	currentWorld: string,
	worldFinishes: {
		[string]: number,
	},
}

local Worlds = { "World1", "World2", "World3" }

local SettingsData = {}
for setting, value in SettingsConfig.Config do
	SettingsData[setting] = value
end

local GamepassesData = {}
for _, gamepassInfo in StoreConfig.Store.Gamepasses do
	GamepassesData[tostring(gamepassInfo.Id)] = false
end

local WorldFinishes = {}
for _, world in ipairs(Worlds) do
	WorldFinishes[world] = 0
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
	teleporting = {
		world = nil,
		origin = nil,
	},
	currentWorld = Worlds[1],
	worldFinishes = WorldFinishes,
}

local Shared = {}

Shared.DEFAULT_PLAYER_DATA = DEFAULT_PLAYER_DATA

return Shared
