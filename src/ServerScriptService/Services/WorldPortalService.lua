local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local PlayerData = require(ReplicatedStorage.PlayerData)

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local TeleportService = game:GetService("TeleportService")
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)

local Local = {}
local Shared = {}

local playerDebounce = {}

local disable = true

function Shared.OnStart()
	-- Add error handling for SetupPortal
	local success, errorMsg = pcall(function()
		Local.SetupPortal()
	end)

	if not success then
		warn("WorldPortalService - Error in SetupPortal:", errorMsg)
	end
end

function Local.SetupPortal()
	-- Check if WorldPortals exists
	if not Workspace:FindFirstChild("WorldPortals") then
		warn("WorldPortalService - WorldPortals folder not found in Workspace")
		return
	end

	for _, descendant in Workspace.WorldPortals:GetDescendants() do
		if descendant.Name == "Inside" then
			descendant.Touched:Connect(function(otherPart: BasePart)
				if disable then
					return
				end

				local player = Players:GetPlayerFromCharacter(otherPart.Parent)

				if player and not playerDebounce[player.UserId] then
					-- Set debounce for this player
					playerDebounce[player.UserId] = true

					local worldName = descendant.Parent.Name
					if not worldName then
						playerDebounce[player.UserId] = nil -- Clear debounce if we exit early
						return
					end

					local placeId = WorldsConfig.GetPlaceIdFromWorldName(worldName)
					if not placeId then
						playerDebounce[player.UserId] = nil -- Clear debounce if we exit early
						return
					end

					local state = PlayerDataService.GetState(player)
					if not state then
						playerDebounce[player.UserId] = nil -- Clear debounce if we exit early
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

					local action = {
						type = "UpdateTeleporting",
						world = worldName,
						origin = "Portal",
					}
					PlayerDataService.UpdateState(player, action)

					-- Attempt to teleport the player
					TeleportService:Teleport(placeId, player, nil)

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
