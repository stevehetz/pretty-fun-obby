local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.SetupSpawnLocations()
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

	local newStage = tonumber(checkpoint.Parent.Name)
	local playerStage = state.stage
	local isNextStage = playerStage + 1 == newStage

	if not isNextStage then
		return false
	end

	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateStage",
		amount = 1,
	}

	PlayerDataService.UpdateState(player, action)

	player.RespawnLocation = checkpoint
	return true
end

return Shared
