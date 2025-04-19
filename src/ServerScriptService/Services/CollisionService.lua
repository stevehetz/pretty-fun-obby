local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Local = {}
local Shared = {}

function Shared.OnStart()
	-- ensure the group exists (skip if you set it up in Studio)
	-- Check if the "Players" collision group already exists
	local groupExists = false
	for _, group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
		if group.name == "Players" then
			groupExists = true
			break
		end
	end

	if not groupExists then
		PhysicsService:RegisterCollisionGroup("Players")
	end
	PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CollisionGroup = "Players"
				end
			end
		end)
	end)
end

return Shared
