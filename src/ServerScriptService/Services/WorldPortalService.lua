local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local PlayerData = require(ReplicatedStorage.PlayerData)

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local TeleportService = game:GetService("TeleportService")
local UpdateState = require(ReplicatedStorage.Functions.UpdateState)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)
local PlayerData = require(ReplicatedStorage.PlayerData)

local Local = {}
local Shared = {}

local playerDebounce = {}

local disable = true

Shared.HandleWorldTeleportComplete = Instance.new("BindableEvent")

-- Scenarios (the below function is called for all of these)
-- 1. Player is just joining the game, they are on world 1, no need to teleport
-- 2. Player is just joining the game, they are on world 2, need to teleport
-- 3. Player is teleported from world 1 to world 2 through a portal
-- 4. Player is teleported from world 2 to world 1 through a portal
-- 5. Player just teleported to world 2 from world 1 and world 2 is booting up
--
-- Once complete, need to call the HandleWorldTeleportComplete to kick off game

function Shared.HandleWorldTeleport(player: Player, state: PlayerData.PlayerData)
	print("HandleWorldTeleport: ", player.Name)
	if not state then
		return
	end

	-- The place ID of the world the player is currently in
	local playersCurrentPlaceId = game.PlaceId

	-- Where the teleport was initiated from
	local teleportingOrigin = state.teleporting.origin

	-- Set when a teleport was initiated
	local teleportingWorld = state.teleporting.world

	-- The last world the player's state was saved to
	local currentWorldFromState = state.currentWorld

	-- The place ID from the world the player's state was saved to
	local currentPlaceIdFromState = WorldsConfig.GetPlaceIdFromWorldName(currentWorldFromState)

	-- Player is just joining the game, restart them where they left off
	if teleportingWorld == nil then
		print("Player is just joining the game")

		-- Player is not in the correct world, teleport them
		if playersCurrentPlaceId ~= currentPlaceIdFromState then
			print("Player is not in the correct world, teleporting them")
			-- Player is not in the correct world, teleport them
			local action = {
				type = "UpdateTeleporting",
				world = state.currentWorld,
				origin = "Join",
			}
			UpdateState(player, action)

			-- Attempt to teleport the player
			TeleportService:Teleport(currentPlaceIdFromState, player, nil)
			return
		end

		print("Player is in the correct world, no need to teleport")

	-- Player was teleported from the above routine
	-- This is the player joining back in after being teleported
	elseif state.teleporting.origin == "Join" then
		print("Player teleported to the correct world after joining the game")
		local action = {
			type = "UpdateTeleporting",
			world = nil,
			origin = nil,
		}
		UpdateState(player, action)

	-- Player was teleported to a world from a portal
	-- This is the player joining back in after being teleported
	-- This was initiated from the SetupPortal() below
	elseif teleportingOrigin == "Portal" then
		print("Teleporting player: ", player.Name, " to world: ", state.teleporting.world)

		-- Update current world
		local updateCurrentWorldAction = {
			type = "UpdateCurrentWorld",
			world = teleportingWorld,
		}
		UpdateState(player, updateCurrentWorldAction)

		-- Clear teleporting state with proper parameters
		local updateTeleportingAction = {
			type = "UpdateTeleporting",
			world = nil,
			origin = nil,
		}
		UpdateState(player, updateTeleportingAction)

		-- Reset stage to 0
		-- Using a direct assignment to ensure it's exactly 0
		local currentStage = player.leaderstats.Stage.Value
		if currentStage ~= 0 then
			player.leaderstats.Stage.Value = 0
			state.stage = 0
		end
	end

	print("HandleWorldTeleport: ", player.Name, " completed")

	Shared.HandleWorldTeleportComplete:Fire(player)
end

function Shared.SetupPortal(state: PlayerData.PlayerData)
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
					UpdateState(player, action)

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
