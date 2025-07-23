local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)

export type PlayerData = PlayerData.PlayerData
local SettingsConfig = require(ReplicatedStorage.Configs.Settings)

local COIN_VALUE = 100

export type UpdateStateAction = {
	type: "UpdateStage",
	amount: number,
} | {
	type: "ResetStage",
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
} | {
	type: "UpdateEquippedPets",
	petName: string,
	value: boolean,
} | {
	type: "UpdateEquippedTrails",
	trailName: string,
	value: boolean,
} | {
	type: "UpdateDoubleJump",
	value: boolean,
} | {
	type: "UpdateCoinCount",
	value: number?,
} | {
	type: "UpdateOneTimePass",
	value: boolean,
} | {
	type: "UpdateDonationTotal",
	amount: number,
} | {
	type: "UpdateHasTrashcan",
	value: boolean,
} | {
	type: "UpdateHasSword",
	value: boolean,
}

return function(playerData: PlayerData.PlayerData, action: UpdateStateAction)
	if action.type == "UpdateStage" then
		playerData.stage += action.amount
	elseif action.type == "ResetStage" then
		playerData.stage = 0
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
		-- handle nil values with print
		playerData.teleporting.world = action.world
		playerData.teleporting.origin = action.origin
	elseif action.type == "UpdateCurrentWorld" then
		playerData.currentWorld = action.world
	elseif action.type == "UpdateEquippedPets" then
		if action.value == true then
			playerData.equippedPets = {}
			playerData.equippedPets = {
				[action.petName] = true,
			}
		elseif action.value == false then
			playerData.equippedPets = {}
			return
		end
	elseif action.type == "UpdateEquippedTrails" then
		print("UpdateEquippedTrails action received:", action.trailName)
		if action.value == true then
			playerData.equippedTrails = {}
			playerData.equippedTrails = {
				[action.trailName] = true,
			}
			print("Equipped trails updated:", playerData.equippedTrails)
		elseif action.value == false then
			playerData.equippedTrails = {}
			return
		end
	elseif action.type == "UpdateDoubleJump" then
		playerData.disableDoubleJump = action.value
	elseif action.type == "UpdateCoinCount" then
		if playerData.coins < 0 then
			playerData.coins = 0
		end
		playerData.coins += action.value or COIN_VALUE
	elseif action.type == "UpdateOneTimePass" then
		playerData.oneTimePass = action.value
	elseif action.type == "UpdateDonationTotal" then
		if playerData.donationTotal == nil then
			playerData.donationTotal = 0
		end
		playerData.donationTotal += action.amount
	elseif action.type == "UpdateHasTrashcan" then
		playerData.hasTrashcan = action.value
	elseif action.type == "UpdateHasSword" then
		playerData.hasSword = action.value
	else
		error("Invalid action type: " .. tostring(action.type))
	end
end
