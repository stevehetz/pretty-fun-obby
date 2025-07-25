local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrailsConfig = require(ReplicatedStorage.Configs.Trails)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerTrailsUpdate = Remotes:WaitForChild("PlayerTrailsUpdate")

-- Store other players' trail data
local PlayerTrails = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	-- Listen for trail updates from the server
	PlayerTrailsUpdate.OnClientEvent:Connect(function(trailsData)
		Local.UpdateAllPlayerTrails(trailsData)
	end)

	-- Set up character events for all players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			-- Wait a moment for the character to fully load
			task.wait(1)

			-- If we have trail data for this player, apply it
			if PlayerTrails[player.UserId] then
				Local.ApplyTrailToPlayer(player, PlayerTrails[player.UserId])
			end
		end)

		player.CharacterRemoving:Connect(function(character)
			local part = character:FindFirstChild("HumanoidRootPart")
			if part then
				Shared.RemoveTrail(part)
			end
		end)
	end)

	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(character)
			-- Wait a moment for the character to fully load
			task.wait(1)

			-- If we have trail data for this player, apply it
			if PlayerTrails[player.UserId] then
				Local.ApplyTrailToPlayer(player, PlayerTrails[player.UserId])
			end
		end)

		player.CharacterRemoving:Connect(function(character)
			local part = character:FindFirstChild("HumanoidRootPart")
			if part then
				Shared.RemoveTrail(part)
			end
		end)
	end
end

function Shared.UpdateEquippedTrail(trailName)
	Remotes.PlayerData.UpdateEquippedTrail:FireServer(trailName)
end

-- Update all player trails based on the data from the server
function Local.UpdateAllPlayerTrails(trailsData)
	-- Store the new trail data
	PlayerTrails = trailsData

	-- Apply trails to all players
	for userId, trailName in pairs(trailsData) do
		local player = Players:GetPlayerByUserId(userId)
		if player and player.Character then
			Local.ApplyTrailToPlayer(player, trailName)
		end
	end
end

-- Apply trail to another player
function Local.ApplyTrailToPlayer(player, trailName)
	if not player or not player.Character then
		return
	end

	local part = player.Character:FindFirstChild("HumanoidRootPart")
	if not part then
		return
	end

	-- Remove any existing trail
	Shared.RemoveTrail(part)

	-- If no trail is equipped, just remove it
	if not trailName then
		return
	end

	-- Add the new trail
	local trailColorSeq = TrailsConfig.GetTrailColor(trailName)
	if trailColorSeq then
		Shared.AddTrail(part, trailColorSeq)
	else
		print("TrailController - No color found for trail:", trailName)
	end
end

function Shared.AddTrail(part, trailColorSeq)
	Shared.RemoveTrail(part)
	local att0 = Instance.new("Attachment", part)
	att0.Position = Vector3.new(0, 2, 0)
	att0.Name = "TrailAttachment0"

	local att1 = Instance.new("Attachment", part)
	att1.Position = Vector3.new(0, -2, 0)
	att1.Name = "TrailAttachment1"

	local trail = Instance.new("Trail", part)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.4
	trail.WidthScale = NumberSequence.new(1)
	trail.Color = trailColorSeq
end

function Shared.RemoveTrail(part)
	local trail = part:FindFirstChildOfClass("Trail")
	if trail then
		trail:Destroy()
	end

	local att0 = part:FindFirstChild("TrailAttachment0")
	if att0 then
		att0:Destroy()
	end

	local att1 = part:FindFirstChild("TrailAttachment1")
	if att1 then
		att1:Destroy()
	end
end

return Shared
