local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

-- Function to register a collision group if it doesn't exist
local function registerCollisionGroup(groupName)
	local groupExists = false
	for _, group in ipairs(PhysicsService:GetRegisteredCollisionGroups()) do
		if group.name == groupName then
			groupExists = true
			break
		end
	end

	if not groupExists then
		PhysicsService:RegisterCollisionGroup(groupName)
	end
end

-- Register collision groups
registerCollisionGroup("Players")
registerCollisionGroup("Enemies")

-- Set collision rules
PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)
PhysicsService:CollisionGroupSetCollidable("Enemies", "Enemies", false) -- Enemies won't collide with each other

-- Set player parts to the Players collision group
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Players"
			end
		end
	end)
end)
