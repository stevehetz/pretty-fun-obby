local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local RespawnService = require(script.Parent.RespawnService)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.Rebirth.OnServerEvent:Connect(Shared.Rebirth)
end

function Shared.Rebirth(player: Player)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local currentStage = state.stage
	local maxStage = StagesConfig.GetTotalStages()
	-- local isAtMaxStage = currentStage >= maxStage
	-- if not isAtMaxStage then
	-- 	return
	-- end

	local rebirthAction: PlayerDataService.UpdateStateAction = {
		type = "Rebirth",
	}

	local stageAction: PlayerDataService.UpdateStateAction = {
		type = "UpdateStage",
		amount = -currentStage + 1
	}

	PlayerDataService.UpdateState(player, rebirthAction)
	PlayerDataService.UpdateState(player, stageAction)
	RespawnService.RespawnPlayer(player)
	BadgesConfig.RewardBadge(player, "Rebirth")
end

return Shared
