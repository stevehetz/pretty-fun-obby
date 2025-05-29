local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

local PlayerData = require(ReplicatedStorage.PlayerData)
local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local TestConfig = require(ReplicatedStorage.Configs.Test)
local StoreConfig = require(ServerStorage.Configs.Store)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

local playerDebounce = {}
Local.pendingTeleports = {}

Shared.HandleWorldTeleportComplete = Instance.new("BindableEvent")
Shared.HandleRebirth = Instance.new("BindableEvent")

function Shared.OnStart()
	Remotes.Teleport.OnServerEvent:Connect(function(player: Player, worldName: string)
		if not player or not player:IsA("Player") then
			return
		end

		local placeId = WorldsConfig.GetPlaceIdFromWorldName(worldName)
		if not placeId then
			warn("WorldPortalService - Invalid world name: " .. tostring(worldName))
			return
		end

		Shared.TeleportPlayer(player, worldName, placeId)
	end)
end

-- Scenarios (the below function is called for all of these)
-- 1. Player is just joining the game, they are on world 1, no need to teleport
-- 2. Player is just joining the game, they are on world 2, need to teleport
-- 3. Player is teleported from world 1 to world 2 through a portal
-- 4. Player is teleported from world 2 to world 1 through a portal
-- 5. Player just teleported to world 2 from world 1 and world 2 is booting up
--
-- Once complete, need to call the HandleWorldTeleportComplete to kick off game

function Shared.HandleWorldTeleport(player: Player, state: PlayerData.PlayerData)
	if not state then
		return
	end

	-- Get the latest state from PlayerDataService when needed
	local getLatestState = function()
		local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
		return PlayerDataService.GetState(player)
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
		-- NEW FLOW - Always start player at World 1
		print("WorldPortalService - Player is just joining the game")

		-- Reset current world to World 1
		state.currentWorld = "World1"

		-- OLD FLOW - Teleport to world they left off at
		-- print("WorldPortalService - Player is just joining the game")
		-- -- Player is not in the correct world, teleport them
		-- if playersCurrentPlaceId ~= currentPlaceIdFromState then
		-- 	-- Player is not in the correct world, teleport them
		-- 	local action = {
		-- 		type = "UpdateTeleporting",
		-- 		world = state.currentWorld,
		-- 		origin = "Join",
		-- 	}
		-- 	local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
		-- 	PlayerDataService.UpdateState(player, action)

		-- 	-- Attempt to teleport the player
		-- 	TeleportService:Teleport(currentPlaceIdFromState, player, nil)
		-- 	return
		-- end

		-- Player was teleported from the above routine
		-- This is the player joining back in after being teleported
	elseif teleportingOrigin == "Join" then
		print("WorldPortalService - Player was teleported from the above routine")

		local action = {
			type = "UpdateTeleporting",
			world = nil,
			origin = nil,
		}
		local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
		PlayerDataService.UpdateState(player, action)

	-- Player was teleported to a world from a portal
	-- This is the player joining back in after being teleported
	-- This was initiated from the SetupPortal() below
	elseif teleportingOrigin == "Portal" then
		print("WorldPortalService - Player was teleported to a world from a portal")
		-- Update current world
		local updateCurrentWorldAction = {
			type = "UpdateCurrentWorld",
			world = teleportingWorld,
		}
		local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
		PlayerDataService.UpdateState(player, updateCurrentWorldAction)

		-- Clear teleporting state with proper parameters
		local updateTeleportingAction = {
			type = "UpdateTeleporting",
			world = nil,
			origin = nil,
		}
		PlayerDataService.UpdateState(player, updateTeleportingAction)

		-- Reset stage to 0
		local currentStage = player.leaderstats.Stage.Value
		if currentStage ~= 0 then
			-- Use the new ResetStage action type to reset the stage to 0
			local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
			PlayerDataService.UpdateState(player, {
				type = "ResetStage",
			})
		end
	end

	Shared.HandleWorldTeleportComplete:Fire(player, state)
end

function Shared.SetupPortals(profiles)
	local WorldPortals = Workspace:FindFirstChild("WorldPortals")
	if not WorldPortals then
		return
	end

	for _, descendant in Workspace.WorldPortals:GetDescendants() do
		if descendant.Name == "Inside" then
			descendant.Touched:Connect(function(otherPart: BasePart)
				local player = Players:GetPlayerFromCharacter(otherPart.Parent)

				if player and not playerDebounce[player.UserId] then
					print("WorldPortalService - player and not playerDebounce[player.UserId]")
					local worldName = descendant.Parent.Name
					if not worldName then
						playerDebounce[player.UserId] = nil -- Clear debounce if we exit early
						return
					end

					-- Check if door is for the current world
					if worldName == WorldsConfig.GetCurrentWorldName() then
						return
					end

					local parent = descendant.Parent
					local access = parent:GetAttribute("Access")
					local isDev = TestConfig.IsDev(player.Name)

					if access == "DevOnly" then
						if isDev then
							print("DevOnly access")
						else
							return
						end
					end

					-- Set debounce for this player
					playerDebounce[player.UserId] = true
					local placeId = WorldsConfig.GetPlaceIdFromWorldName(worldName)
					if not placeId then
						playerDebounce[player.UserId] = nil -- Clear debounce if we exit early
						return
					end

					-- Can always teleport to World 1
					if worldName ~= "World1" then
						-- check if player owns premium world pass gamepass
						-- Check if owns premium world pass
						local state = profiles[player].Data
						local worldPassInfo = StoreConfig.GetStoreItemInfo("Premium World Pass")
						local ownsPremiumWorldPass = worldPassInfo
							and state.gamepasses[tostring(worldPassInfo.Id)] ~= nil
						if not ownsPremiumWorldPass then
							MarketplaceService:PromptGamePassPurchase(player, worldPassInfo.Id)
							task.delay(3, function()
								if playerDebounce[player.UserId] then
									playerDebounce[player.UserId] = nil
								end
							end)
							return
						end
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
					print("WorldPortalService - Freezing player movement")
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

					print("WorldPortalService - Teleporting player")
					Shared.TeleportPlayer(player, worldName, placeId)

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

function Shared.TeleportPlayer(player: Player, worldName: string, placeId: number)
	local action = {
		type = "UpdateTeleporting",
		world = worldName,
		origin = "Portal",
	}
	print("WorldPortalService - TeleportPlayer - action: ", action.type, action.world, action.origin)

	-- Use the UpdateState function from PlayerDataService to ensure the state is updated in the profile
	local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
	PlayerDataService.UpdateState(player, action)

	task.spawn(function()
		-- Attempt to teleport the player
		TeleportService:Teleport(placeId, player, nil)
	end)
end

-- Expose pendingTeleports through the Shared table
Shared.pendingTeleports = Local.pendingTeleports

return Shared
