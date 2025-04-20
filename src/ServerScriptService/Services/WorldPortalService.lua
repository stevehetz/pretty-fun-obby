local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TeleportService = game:GetService("TeleportService")
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RebirthService = require(ServerScriptService.Services.RebirthService)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)

local checkpointDebounce = {}

local PLACE_IDS = {
	[1] = 139398903012255,
	[2] = 71122824760185,
}

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.SetupPortal()

	-- Players.PlayerAdded:Connect(function(player: Player)
	-- 	BadgesConfig.RewardBadge(player, "Pretty Fun Obby")
	-- end)
end

function Local.SetupPortal()
	for _, descendant in Workspace.WorldPortals:GetDescendants() do
		if descendant.Name == "Inside" then
			descendant.Touched:Connect(function(otherPart: BasePart)
				local player = Players:GetPlayerFromCharacter(otherPart.Parent)

				if player then
					-- the player must have completed all the stages
					-- local state = PlayerDataService.GetState(player)
					-- if not state then
					-- 	return false
					-- end
					-- local playerStage = state.stage
					-- local isLastStage = playerStage == StagesConfig.GetTotalStages()
					-- if not isLastStage then
					-- 	return false
					-- end

					-- local action = {
					-- 	type = "UpdateFinishes",
					-- 	amount = 1,
					-- }
					-- PlayerDataService.UpdateState(player, action)
					-- local worldNumber = tonumber(descendant.Parent.Name)
					-- if not worldNumber then
					-- 	return
					-- end

					-- local placeId = PLACE_IDS[worldNumber]
					-- if not placeId then
					-- 	return
					-- end

					-- local state = PlayerDataService.GetState(player)
					-- if not state then
					-- 	return
					-- end

					-- local playerStage = state.stage
					-- if playerStage > 0 then
					-- 	local action = {
					-- 		type = "UpdateStage",
					-- 		amount = -playerStage,
					-- 	}
					-- 	PlayerDataService.UpdateState(player, action)
					-- end

					-- TeleportService:Teleport(placeId, player, { enteredWorld = worldNumber })
				end
			end)
		end
	end
end

return Shared
