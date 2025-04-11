local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)

export type PlayerData = PlayerData.PlayerData
local SettingsConfig = require(ReplicatedStorage.Configs.Settings)

export type UpdateStateAction = {
	type: "UpdateStage",
	amount: number,
} | {
	type: "UpdateDeaths",
	amount: number,
} | {
	type: "UpdateSetting",
	setting: SettingsConfig.Setting,
	value: boolean,
} | {
	type: "EarnSkip",
	amount: number?,
} | {
	type: "UseSkip",
} | {
	type: "Rebirth",
	amount: number?
}

return function(playerData: PlayerData.PlayerData, action: UpdateStateAction)
	if action.type == "UpdateStage" then
		playerData.stage += action.amount
	elseif action.type == "UpdateDeaths" then
		playerData.deaths += action.amount
	elseif action.type == "Rebirth" then
		playerData.rebirths += action.amount or 1
	elseif action.type == "UpdateSetting" then
		playerData.settings[action.setting] = action.value
	elseif action.type == "EarnSkip" then
		action.amount = action.amount or 1
		playerData.skips.amount += action.amount
		local SKIPS_COOLDOWN_SECONDS = 120
		playerData.skips.next = os.time() + SKIPS_COOLDOWN_SECONDS
	elseif action.type == "UseSkip" then
		playerData.skips.amount -= 1
	end
end
