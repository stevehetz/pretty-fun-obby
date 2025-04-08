export type Setting = "Easy Mode" | "Music" | "Sound Effects" | "Menu Blur"

type SettingsConfig = {
	[Setting]: boolean
}

local Config: SettingsConfig = {
	["Easy Mode"] = false,
	["Music"] = true,
	["Sound Effects"] = true,
	["Menu Blur"] = true
}

local Local = {}
local Shared = {}

Shared.Config = Config

function Shared.GetSettingValue(data, setting: Setting)
	return data.settings[setting]
end

return Shared