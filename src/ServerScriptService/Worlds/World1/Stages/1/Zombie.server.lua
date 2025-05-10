WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)

local placeId = game.PlaceId
local worldName = "World1"
local worldPlaceId = WorldsConfig.GetPlaceIdFromWorldName(worldName)

if placeId ~= worldPlaceId then
	return
end

local rig = game.Workspace.Rigs.Zombie
local animationAssetId = "rbxassetid://137589538429321"

local isAnimationPlaying = false
local attackDistance = 50
local damageAmount = 60
local canDamage = true
local damageCooldown = 1

-- Get the platform that the zombie is on
local platform = rig.Parent:FindFirstChild("ZombiePlatform") or workspace:FindFirstChild("ZombiePlatform")
if not platform then
	-- If no specific platform is found, try to find what the zombie is standing on
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { rig }

	local raycastResult = workspace:Raycast(rig.HumanoidRootPart.Position, Vector3.new(0, -10, 0), raycastParams)
	if raycastResult and raycastResult.Instance then
		platform = raycastResult.Instance
		print("Detected platform:", platform:GetFullName())
	end
end

-- Define platform boundaries
local platformBoundaries = {
	min = Vector3.new(-math.huge, -math.huge, -math.huge),
	max = Vector3.new(math.huge, math.huge, math.huge),
}

if platform then
	local platformSize = platform.Size
	local platformPosition = platform.Position
	local platformCFrame = platform.CFrame

	-- Calculate platform boundaries in world space
	local halfSize = platformSize / 2
	local cornerOffset = Vector3.new(halfSize.X, 0, halfSize.Z) -- Ignore Y to allow movement up/down on the platform

	-- Add a small margin to prevent the zombie from walking right on the edge
	local margin = 1
	cornerOffset = cornerOffset - Vector3.new(margin, 0, margin)

	-- Calculate min and max points in world space
	platformBoundaries.min = platformPosition - cornerOffset
	platformBoundaries.max = platformPosition + cornerOffset

	print("Platform boundaries set: Min =", platformBoundaries.min, "Max =", platformBoundaries.max)
end

-- Function to check if a position is within platform boundaries
local function isPositionOnPlatform(position)
	-- Always allow Y movement (up/down)
	return position.X >= platformBoundaries.min.X
		and position.X <= platformBoundaries.max.X
		and position.Z >= platformBoundaries.min.Z
		and position.Z <= platformBoundaries.max.Z
end

local animation = Instance.new("Animation")
animation.AnimationId = animationAssetId
animation.Parent = rig.Humanoid

local animator = rig.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", rig.Humanoid)
local animTrack = animator:LoadAnimation(animation)
-- bump priority so it overrides the default animate script
animTrack.Priority = Enum.AnimationPriority.Action

animTrack:GetMarkerReachedSignal("Pause"):Connect(function()
	if isAnimationPlaying then
		animTrack:AdjustSpeed(0)
	else
		animTrack:AdjustSpeed(1)
	end
end)

task.wait(1)

-- Set up touch detection for damage
local function setupTouchDamage(part)
	part.Touched:Connect(function(hit)
		-- Check if the part that was touched belongs to a player
		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)

		-- Only proceed if it's a player and we can damage
		if player and canDamage then
			local humanoid = character:FindFirstChild("Humanoid")

			if humanoid and humanoid.Health > 0 then
				-- Apply damage
				humanoid:TakeDamage(damageAmount)
				print("Damaged player " .. player.Name .. " for " .. damageAmount .. " health")

				-- Set cooldown
				canDamage = false
				task.delay(damageCooldown, function()
					canDamage = true
				end)
			end
		end
	end)
end

-- Define which parts are considered the "front" of the zombie
local frontParts = {
	["LeftHand"] = true,
	["RightHand"] = true,
	-- Add any other parts that should be considered "front" parts
}

-- Set up touch detection only for front parts of the zombie
for _, part in pairs(rig:GetDescendants()) do
	if part:IsA("BasePart") and frontParts[part.Name] then
		print("Setting up damage for front part:", part.Name)
		setupTouchDamage(part)
	end
end

local movingToPlayerId = nil

-- Make the FollowPlayer function non-recursive to prevent stack overflow
function FollowPlayer(player)
	while true do
		if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			movingToPlayerId = nil
			return
		end

		local humanoidRootPart = rig.HumanoidRootPart
		local humanoidPosition = humanoidRootPart.Position
		local playerCharacter = player.Character
		local playerHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
		local playerPosition = playerHumanoidRootPart.Position
		local distanceFromRig = (playerPosition - humanoidPosition).Magnitude

		-- Player too far away, stop following
		if distanceFromRig > attackDistance then
			movingToPlayerId = nil
			rig.Humanoid:MoveTo(rig.HumanoidRootPart.Position)

			-- Stop animation when not moving
			if isAnimationPlaying then
				animTrack:AdjustSpeed(1)
				isAnimationPlaying = false
			end

			return
		end

		-- Within the attack distance, move towards the player
		if distanceFromRig < attackDistance and distanceFromRig > -1 then
			local targetPosition = player.Character.HumanoidRootPart.Position

			-- Check if the target position is within the platform boundaries
			if isPositionOnPlatform(targetPosition) then
				rig.Humanoid:MoveTo(targetPosition)

				-- Play animation when moving
				if not isAnimationPlaying then
					animTrack:AdjustSpeed(1)
					animTrack:Play()
					isAnimationPlaying = true
				end
			else
				-- If target is off platform, move to the closest point on the platform
				local clampedPosition = Vector3.new(
					math.clamp(targetPosition.X, platformBoundaries.min.X, platformBoundaries.max.X),
					targetPosition.Y,
					math.clamp(targetPosition.Z, platformBoundaries.min.Z, platformBoundaries.max.Z)
				)

				rig.Humanoid:MoveTo(clampedPosition)

				-- Play animation when moving
				if not isAnimationPlaying then
					animTrack:AdjustSpeed(1)
					animTrack:Play()
					isAnimationPlaying = true
				end
			end

			task.wait(0.2)
		else
			rig.Humanoid:MoveTo(rig.HumanoidRootPart.Position)

			task.wait(0.2)
		end
	end
end

-- Main loop
while task.wait(1) do
	-- Only look for players to follow if we're not already following someone
	if movingToPlayerId == nil then
		-- Look for a player to follow
		for _, player in ipairs(game.Players:GetPlayers()) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- If Player is within range of the rig, move the rig to the player
				local startMoveDistance = (rig.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude

				if startMoveDistance < attackDistance then
					movingToPlayerId = player.UserId
					-- Start following in a separate thread to avoid blocking the main loop
					task.spawn(function()
						FollowPlayer(player)
					end)
					break -- Found a player to follow, exit the loop
				end
			end
		end
	end
end
