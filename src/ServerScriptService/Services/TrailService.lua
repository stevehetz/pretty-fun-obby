local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Create a new remote event for trail updates if it doesn't exist
if not Remotes:FindFirstChild("PlayerTrailUpdate") then
	local trailUpdateEvent = Instance.new("RemoteEvent")
	trailUpdateEvent.Name = "PlayerTrailUpdate"
	trailUpdateEvent.Parent = Remotes
end

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.PlayerData.UpdateEquippedTrail.OnServerEvent:Connect(function(player, trail)
		Shared.UpdateEquippedTrails(player, trail)
	end)

	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		Shared.BroadcastPlayerTrail(player)
	end)

	-- For players already in the game
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			Shared.BroadcastPlayerTrail(player)
		end

		player.CharacterAdded:Connect(function(character)
			Shared.BroadcastPlayerTrail(player)
		end)
	end
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

	-- Broadcast the trail update to all clients
	Shared.BroadcastPlayerTrail(player)
end

-- Function to broadcast a player's trail to all clients
function Shared.BroadcastPlayerTrail(player: Player)
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

	-- Broadcast to all clients
	Remotes.PlayerTrailUpdate:FireAllClients(player.UserId, equippedTrail)
end

return Shared
