local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	print("RespawnService OnStart")
	PlayerDataService.ProfileLoaded.Event:Connect(Shared.RespawnPlayer)
	Remotes.Respawn.OnServerEvent:Connect(function(player: Player, isDeath: boolean)
		if isDeath then
			local action: PlayerDataService.UpdateStateAction = {
				type = "UpdateDeaths",
				amount = 1,
			}
			PlayerDataService.UpdateState(player, action)
		end
		Shared.RespawnPlayer()
	end)
end

function Shared.RespawnPlayer(player: Player)
	local playerState = PlayerDataService.GetState(player)
	if not playerState then
		return
	end

	local stage = playerState.stage
	local spawnLocation = StagesConfig.GetSpawnlocation(stage)
	if not spawnLocation then
		return
	end

	player:RequestStreamAroundAsync(spawnLocation.Position)

	local character = player.Character
	print("server - teleport player")
	local primaryPart = character.PrimaryPart
	if character and primaryPart then
		local distanceBetween = (primaryPart.Position - spawnLocation.Position).Magnitude
		if distanceBetween < 25 then
			return
		end
		character:PivotTo(spawnLocation.CFrame)
	end
end

return Shared
