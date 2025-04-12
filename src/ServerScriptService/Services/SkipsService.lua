local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ProgressService = require(ServerScriptService.Services.ProgressService)
local RespawnService = require(ServerScriptService.Services.RespawnService)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.SkipLoop()
	Remotes.Skip.OnServerEvent:Connect(Local.SkipStage)
end

function Local.SkipLoop()
	task.spawn(function()
		while true do
			pcall(function()
				for _, player in Players:GetPlayers() do
					local state = PlayerDataService.GetState(player)
					if not state then
						continue
					end

					local nextStipTime = state.skips.next
					local currentTime = os.time()
					local isBeforeNextSkip = nextStipTime > currentTime
					if isBeforeNextSkip then
						continue
					end

					local isVip = state.vip
					local action: PlayerDataService.UpdateStateAction = {
						type = "EarnSkip",
						amount = isVip and 2 or 1,
					}
					PlayerDataService.UpdateState(player, action)
				end
			end)
			task.wait(1)
		end
	end)
end

function Local.SkipStage(player: Player)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	-- local hasSkips = state.skips.amount > 0
	-- if not hasSkips then
	-- 	return
	-- end

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
