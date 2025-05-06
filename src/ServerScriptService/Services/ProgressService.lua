local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RebirthService = require(ServerScriptService.Services.RebirthService)
local TestService = require(ServerScriptService.Services.TestService)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)

local checkpointDebounce = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.SetupSpawnLocations()

	Players.PlayerAdded:Connect(function(player: Player)
		BadgesConfig.RewardBadge(player, "Pretty Fun Obby")
	end)
end

function Local.SetupSpawnLocations()
	for _, descendant in Workspace.Stages:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			descendant.Touched:Connect(function(otherPart: BasePart)
				local player = Players:GetPlayerFromCharacter(otherPart.Parent)
				if player then
					Shared.TouchCheckpoint(player, descendant)
				end
			end)
		end
	end
end

function Shared.TouchCheckpoint(player: Player, checkpoint: SpawnLocation)
	local state = PlayerDataService.GetState(player)
	if not state then
		return false
	end

	-- Keep the debounce as it's working
	-- local debounceKey = player.UserId .. "_" .. tostring(checkpoint:GetFullName())
	-- if checkpointDebounce[debounceKey] then
	--     return false
	-- end

	-- Set debounce immediately
	-- checkpointDebounce[debounceKey] = true

	-- Process checkpoint logic
	local newStage = tonumber(checkpoint.Parent.Name)
	local playerStage = state.stage
	local isNextStage = playerStage + 1 == newStage

	if not isNextStage then
		-- checkpointDebounce[debounceKey] = nil
		return false
	end

	-- Update stage first before badge reward to prevent any race conditions
	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateStage",
		amount = 1,
	}
	PlayerDataService.UpdateState(player, action)

	-- Set respawn location
	player.RespawnLocation = checkpoint

	-- Award badge after all other operations are complete
	-- local is10thStage = newStage % 10 == 0
	-- if is10thStage then
	-- 	task.spawn(function() -- Run in a separate thread to prevent any blocking
	-- 		BadgesConfig.RewardBadge(player, "Stage 10")
	-- 	end)
	-- end

	-- Maintain a longer debounce for extra safety
	-- task.delay(2, function()
	--     checkpointDebounce[debounceKey] = nil
	-- end)

	return true
end

return Shared
