local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RebirthService = require(ServerScriptService.Services.RebirthService)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)

local checkpointDebounce = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	-- Old, Disable once handling teleports in world portal service
	Local.SetupPortal()

	-- Players.PlayerAdded:Connect(function(player: Player)
	-- 	BadgesConfig.RewardBadge(player, "Pretty Fun Obby")
	-- end)
end

function Local.SetupPortal()
	for _, descendant in Workspace.EndPortal:GetDescendants() do
		if descendant.Name == "Inside" then
			descendant.Touched:Connect(function(otherPart: BasePart)
				local player = Players:GetPlayerFromCharacter(otherPart.Parent)

				if player then
					-- the player must have completed all the stages
					local state = PlayerDataService.GetState(player)
					if not state then
						return false
					end
					local playerStage = state.stage
					local isLastStage = playerStage == StagesConfig.GetTotalStages()
					if not isLastStage then
						return false
					end

					local action = {
						type = "UpdateFinishes",
						amount = 1,
					}
					PlayerDataService.UpdateState(player, action)

					RebirthService.Rebirth(player)
				end
			end)
		end
	end
end

return Shared
