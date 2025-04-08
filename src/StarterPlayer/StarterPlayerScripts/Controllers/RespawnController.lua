local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local StateController = require(script.Parent.StateController)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.SetRespawnLocation()
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateStage" or action.type == "RestartGame" then
			Local.SetRespawnLocation()
		elseif action.type == "UseSkip" then
			Shared.RespawnPlayer(Player.Character, false)
		end
	end)

	local character = Player.Character or Player.CharacterAdded:Wait()
	if character then
		Shared.RespawnPlayer(character)
	end

	Player.CharacterAdded:Connect(function(character)
		Shared.RespawnPlayer(character, true)
	end)
end

function Local.SetRespawnLocation()
	local totalStages = StagesConfig.GetTotalStages()
	local currentStage = StateController.GetState().stage
	if totalStages == currentStage then
		Remotes.PlayerData.Restart:FireServer()
	else
		local spawnLocation = StagesConfig.GetSpawnlocation(currentStage)
		Player.RespawnLocation = spawnLocation
		if currentStage == 1 then
			local character = Player.Character or Player.CharacterAdded:Wait()
			if character then
				Shared.RespawnPlayer(character, false)
			end
		end
	end
end

function Shared.RespawnPlayer(character: Model, isDeath: boolean)
	local respsawnLocation = Player.RespawnLocation
	if not respsawnLocation then
		return
	end

	local hasTeleported = false
	while not hasTeleported do
		local primarypart = character.PrimaryPart
		if not primarypart or not primarypart.Position then
			task.wait(0.01)
			continue
		end

		print("client - teleport player")
		character:PivotTo(respsawnLocation.CFrame + Vector3.new(0, 3, 0))

		local distanceBetween = (primarypart.Position - respsawnLocation.Position).Magnitude
		if distanceBetween < 5 then
			hasTeleported = true
		end

		task.wait(0.01)
	end

	Remotes.Respawn:FireServer(isDeath)
end

return Shared
