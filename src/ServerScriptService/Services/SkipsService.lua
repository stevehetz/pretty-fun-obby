local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ProgressService = require(ServerScriptService.Services.ProgressService)
local RespawnService = require(ServerScriptService.Services.RespawnService)
local TestService = require(ServerScriptService.Services.TestService)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.Skip.OnServerEvent:Connect(Local.SkipStage)
end

function Local.SkipStage(player: Player)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	-- if TestService.IsDev() then
	-- 	local currentStage = state.stage
	-- 	local lastStage = StagesConfig.GetTotalStages() - currentStage
	-- 	local action: PlayerDataService.UpdateStateAction = {
	-- 		type = "UpdateStage",
	-- 		amount = lastStage,
	-- 	}
	-- 	PlayerDataService.UpdateState(player, action)
	-- 	RespawnService.RespawnPlayer(player)
	-- 	return
	-- end

	local hasSkips = state.skips.amount > 0
	if not hasSkips then
		return
	end

	local currentStage = state.stage
	local maxStage = StagesConfig.GetTotalStages()
	local isAtMaxStage = currentStage >= maxStage
	if isAtMaxStage then
		return
	end

	local nextStage = currentStage + 1
	local spawnLocation = StagesConfig.GetSpawnlocation(nextStage)
	if not spawnLocation then
		return
	end

	local didSkipStage = ProgressService.TouchCheckpoint(player, spawnLocation)
	if not didSkipStage then
		return
	end

	local action: PlayerDataService.UpdateStateAction = {
		type = "UseSkip",
	}
	PlayerDataService.UpdateState(player, action)
	RespawnService.RespawnPlayer(player)
end

return Shared
