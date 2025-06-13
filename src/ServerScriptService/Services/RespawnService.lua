local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local Remotes = ReplicatedStorage.Remotes

local Shared = {}

function Shared.OnStart()
	-- Set player respawn time to 0 (instant respawn)
	Players.RespawnTime = 0

	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		-- print("RespawnService - PlayerDataService.ProfileLoaded.Event")
		Shared.RespawnPlayer(player)
	end)
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

function Shared.RestartPlayer(player: Player)
	local playerState = PlayerDataService.GetState(player)
	if not playerState then
		return
	end

	local stage = playerState.stage

	if stage > 0 then
		local action: PlayerDataService.UpdateStateAction = {
			type = "UpdateStage",
			amount = -stage,
		}
		PlayerDataService.UpdateState(player, action)
	end

	-- local action: PlayerDataService.UpdateStateAction = {
	-- 	type = "UpdateStage",
	-- 	amount = 35,
	-- }
	-- PlayerDataService.UpdateState(player, action)

	Shared.RespawnPlayer(player)
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
	if not character then
		return
	end
	local primaryPart = character.PrimaryPart
	if primaryPart then
		local distanceBetween = (primaryPart.Position - spawnLocation.Position).Magnitude
		if distanceBetween < 25 then
			return
		end
		character:PivotTo(spawnLocation.CFrame)
	end
end

return Shared
