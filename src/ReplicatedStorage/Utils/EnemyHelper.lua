local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BoundaryHelper = require(ReplicatedStorage.Utils.BoundaryHelper)

export type EnemyHelperConfig = {
	rig: Model,
	platformBoundaries: {
		min: Vector3,
		max: Vector3,
	},
	damageAmount: number,
	damageCooldown: number,
	attackDistance: number,
	animationAssetId: string,
}

local Local = {}
local Shared = {}

function Shared.EnableAttack(config: EnemyHelperConfig)
	local rig = config.rig
	local platformBoundaries = config.platformBoundaries
	local attackDistance = config.attackDistance or 50
	local damageAmount = config.damageAmount or 60
	local damageCooldown = config.damageCooldown or 1
	local animationAssetId = config.animationAssetId
	local damageParts = config.damageParts or {}
	local isAnimationPlaying = false
	local canDamage = true

	local function setupTouchDamage(part, damageAmount, damageCooldown)
		-- Set up touch detection for damage
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

	-- Set up touch detection only for front parts of the zombie
	for _, part in pairs(rig:GetDescendants()) do
		if part:IsA("BasePart") and table.find(damageParts, part.Name) then
			setupTouchDamage(part, damageAmount, damageCooldown)
		end
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

	-- Main loop
	local movingToPlayerId = nil

	local function followPlayer(player, rig, attackDistance, platformBoundaries)
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
				if BoundaryHelper.IsPositionOnPlatform(targetPosition, platformBoundaries) then
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

	while task.wait(1) do
		-- Only look for players to follow if we're not already following someone
		if movingToPlayerId == nil then
			-- Look for a player to follow
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					-- If Player is within range of the rig, move the rig to the player
					local startMoveDistance = (
						rig.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position
					).Magnitude

					if startMoveDistance < attackDistance then
						movingToPlayerId = player.UserId
						-- Start following in a separate thread to avoid blocking the main loop
						task.spawn(function()
							followPlayer(player, rig, attackDistance, platformBoundaries)
						end)
						break -- Found a player to follow, exit the loop
					end
				end
			end
		end
	end
end

return Shared
