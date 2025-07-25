local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create remote events if they don't exist
if not Remotes:FindFirstChild("PlayerTrailsUpdate") then
	local trailUpdateEvent = Instance.new("RemoteEvent")
	trailUpdateEvent.Name = "PlayerTrailsUpdate"
	trailUpdateEvent.Parent = Remotes
end

local Local = {}
local Shared = {}

-- Store all player trails in a single table (userId -> trailName)
local PlayerTrails = {}

function Shared.OnStart()
	Remotes.PlayerData.UpdateEquippedTrail.OnServerEvent:Connect(function(player, trail)
		Shared.UpdateEquippedTrails(player, trail)
	end)

	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		Shared.UpdatePlayerTrail(player)
	end)

	-- For players already in the game
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			Shared.UpdatePlayerTrail(player)
		end

		player.CharacterAdded:Connect(function(character)
			Shared.UpdatePlayerTrail(player)
		end)
	end

	Players.PlayerAdded:Connect(function(newPlayer)
		-- Set up CharacterAdded event for new players
		if newPlayer.Character then
			Shared.UpdatePlayerTrail(newPlayer)
		end

		newPlayer.CharacterAdded:Connect(function(character)
			Shared.UpdatePlayerTrail(newPlayer)
		end)

		-- Handle player removal
		newPlayer.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				-- Player left the game, remove from PlayerTrails
				PlayerTrails[newPlayer.UserId] = nil
				-- Broadcast the updated table to all clients
				print(PlayerTrails)
				Shared.BroadcastAllTrails()
			end
		end)
	end)
end

function Shared.UpdateEquippedTrails(player: Player, trail: Trail)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local currentValue = state.equippedTrails[trail]
	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateEquippedTrails",
		trailName = trail,
		value = not currentValue,
	}

	PlayerDataService.UpdateState(player, action)

	-- Update the player's trail in our table and broadcast
	Shared.UpdatePlayerTrail(player)
end

-- Function to update a player's trail in the PlayerTrails table
function Shared.UpdatePlayerTrail(player: Player)
	local state = PlayerDataService.GetState(player)
	if not state or not state.equippedTrails then
		return
	end

	-- Find the equipped trail
	local equippedTrail = nil
	for trailName, isEquipped in pairs(state.equippedTrails) do
		if isEquipped then
			equippedTrail = trailName
			break
		end
	end

	-- Update the PlayerTrails table
	PlayerTrails[player.UserId] = equippedTrail

	print("TrailsService - Updated PlayerTrails for", player.Name, ":", equippedTrail)

	-- Broadcast the updated table to all clients
	Shared.BroadcastAllTrails()
end

-- Function to broadcast the entire PlayerTrails table to all clients
function Shared.BroadcastAllTrails()
	Remotes.PlayerTrailsUpdate:FireAllClients(PlayerTrails)
end

return Shared
