local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerData = require(ReplicatedStorage.PlayerData)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local WorldPortalService = require(ServerScriptService.Services.WorldPortalService)

local Local = {}
local Shared = {}

local playerDebounce = {}

Shared.OnStart = function()
	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		-- print("EndPortalService - PlayerDataService.ProfileLoaded.Event")
		local playerState = PlayerDataService.GetState(player)
		if not playerState then
			return
		end
		Local.SetupPortal(player, playerState)
	end)
end

Local.SetupPortal = function(player: Player, initialState: PlayerData.PlayerData)
	local EndPortal = Workspace:FindFirstChild("EndPortal")
	if not EndPortal then
		return
	end

	for _, descendant in Workspace.EndPortal:GetDescendants() do
		if descendant.Name == "Inside" then
			descendant.Touched:Connect(function(otherPart: BasePart)
				local player = Players:GetPlayerFromCharacter(otherPart.Parent)

				if player and not playerDebounce[player.UserId] then
					-- print("EndPortalService - player and not playerDebounce[player.UserId]")
					-- Always get the latest state from PlayerDataService
					local currentState = PlayerDataService.GetState(player)
					if not currentState then
						playerDebounce[player.UserId] = nil
						return
					end
					local playerStage = currentState.stage
					local isLastStage = playerStage == StagesConfig.GetTotalStages()
					if not isLastStage then
						playerDebounce[player.UserId] = nil
						return
					end

					local worldName = descendant.Parent.Name
					if not worldName then
						playerDebounce[player.UserId] = nil
						return
					end

					-- print("EndPortalService - worldName: " .. worldName)

					-- Set debounce for this player
					playerDebounce[player.UserId] = true

					local placeId = WorldsConfig.GetPlaceIdFromWorldName(worldName)
					if not placeId then
						playerDebounce[player.UserId] = nil -- Clear debounce if we exit early
						return
					end

					-- If in studio, do not teleport or freeze the player
					if RunService:IsStudio() then
						task.delay(3, function()
							if playerDebounce[player.UserId] then
								playerDebounce[player.UserId] = nil
							end
						end)
						return
					end

					-- Freeze the player so they can't move
					local character = player.Character
					if character and character:FindFirstChild("Humanoid") then
						local humanoid = character.Humanoid
						-- Store original values to restore if teleport fails
						playerDebounce[player.UserId] = {
							active = true,
							originalWalkSpeed = humanoid.WalkSpeed,
							originalJumpHeight = humanoid.JumpHeight,
						}

						-- Freeze player movement
						humanoid.WalkSpeed = 0
						humanoid.JumpHeight = 0
					end

					WorldPortalService.TeleportPlayer(player, worldName, placeId)

					-- Reset the debounce after 3 seconds
					-- This is needed in case teleport fails or player stays in range
					task.delay(3, function()
						if playerDebounce[player.UserId] then
							local playerData = playerDebounce[player.UserId]
							playerDebounce[player.UserId] = nil

							-- If player is still in the game (teleport failed), unfreeze them
							if player and player.Character and player.Character:FindFirstChild("Humanoid") then
								local humanoid = player.Character.Humanoid
								-- Reset to original values if teleport failed
								if type(playerData) == "table" then
									humanoid.WalkSpeed = playerData.originalWalkSpeed
									humanoid.JumpHeight = playerData.originalJumpHeight or 7.2 -- Default from ToolsController
								end
							end
						end
					end)
				end
			end)
		end
	end
end

return Shared
