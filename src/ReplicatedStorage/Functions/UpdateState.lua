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
	type: "UpdateVip",
	value: boolean,
} | {
	type: "UpdateGamepass",
	value: boolean,
	gamepassId: string,
} | {
	type: "UpdateFinishes",
	amount: number,
} | {
	type: "UpdateWorldFinishes",
	world: string,
	amount: number,
} | {
	type: "UpdateTeleporting",
	world: string,
	origin: "Portal" | "Join" | nil,
} | {
	type: "UpdateCurrentWorld",
	world: string,
}

return function(playerData: PlayerData.PlayerData, action: UpdateStateAction)
	if action.type == "UpdateStage" then
		playerData.stage += action.amount
	elseif action.type == "UpdateDeaths" then
		playerData.deaths += action.amount
	elseif action.type == "UpdateSetting" then
		playerData.settings[action.setting] = action.value
	elseif action.type == "EarnSkip" then
		action.amount = action.amount or 1
		if playerData.skips.amount < 0 then
			playerData.skips.amount = 0
		end
		playerData.skips.amount += action.amount
	elseif action.type == "UseSkip" then
		playerData.skips.amount -= 1
	elseif action.type == "UpdateVip" then
		playerData.vip = action.value
	elseif action.type == "UpdateGamepass" then
		playerData.gamepasses[tostring(action.gamepassId)] = action.value
	elseif action.type == "UpdateFinishes" then
		playerData.finishes += action.amount
	elseif action.type == "UpdateWorldFinishes" then
		if playerData.worldFinishes[action.world] == nil then
			playerData.worldFinishes[action.world] = 0
		end
		playerData.worldFinishes[action.world] += action.amount
	elseif action.type == "UpdateTeleporting" then
		playerData.teleporting.world = action.world
		playerData.teleporting.origin = action.origin
	elseif action.type == "UpdateCurrentWorld" then
		playerData.currentWorld = action.world
	else
		error("Invalid action type: " .. tostring(action.type))
	end
end
