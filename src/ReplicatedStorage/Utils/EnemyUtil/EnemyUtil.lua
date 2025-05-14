local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local BoundaryUtil = require(ReplicatedStorage.Utils.BoundaryUtil)

local EnemyAnimate = require(ReplicatedStorage.Utils.EnemyUtil.EnemyAnimate)
local EnemyTouchDamage = require(ReplicatedStorage.Utils.EnemyUtil.EnemyTouchDamage)

export type EnemyUtilConfig = {
	rig: Model,
	platformBoundaries: {
		min: Vector3,
		max: Vector3,
	},
	platform: BasePart?,
	setPlatformBoundaries: boolean?,
	damageAmount: number,
	damageCooldown: number,
	attackDistance: number,
	animationAssetId: string,
	damageParts: { string }?,
	movingToPlayerId: number?,
	originalPosition: Vector3?,
}

local Local = {}
local Shared = {}

-- Function to set collision group for all parts in a model
local function setCollisionGroup(model, groupName)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

function Shared.EnableAttack(config: EnemyUtilConfig)
	local rig = config.rig
	local setPlatformBoundaries = config.setPlatformBoundaries
	local attackDistance = config.attackDistance or 50
	local damageAmount = config.damageAmount or 60
	local damageCooldown = config.damageCooldown or 1
	local animationAssetId = config.animationAssetId
	local damageParts = config.damageParts or {}

	-- Set collision group for all enemy parts to prevent them from pushing/climbing each other
	-- setCollisionGroup(rig, "Enemies")

	local animateEnemy = EnemyAnimate.Create(animationAssetId, rig)

	EnemyTouchDamage.Setup(rig, damageParts, damageAmount, damageCooldown)

	while task.wait(1) do
		-- Only look for players to follow if we're not already following someone
		if config.movingToPlayerId == nil then
			-- Look for a player to follow
			for _, player in ipairs(game.Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					-- If Player is within range of the rig, move the rig to the player
					local startMoveDistance = (
						rig.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position
					).Magnitude

					if startMoveDistance < attackDistance then
						config.movingToPlayerId = player.UserId

						local platformBoundaries = {
							min = Vector3.new(-math.huge, -math.huge, -math.huge),
							max = Vector3.new(math.huge, math.huge, math.huge),
						}

						if setPlatformBoundaries then
							-- Use the provided platform if available, otherwise use raycast
							platformBoundaries = BoundaryUtil.GetBoundaryOfRig(rig, config.platform)
						end

						task.spawn(function()
							Local.FollowPlayer(config, player, platformBoundaries, animateEnemy)
						end)
						break -- Found a player to follow, exit the loop
					end
				end
			end
		end
	end
end

function Local.FollowPlayer(config, player, platformBoundaries, animateEnemy)
	while true do
		if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			config.movingToPlayerId = nil
			return
		end

		local distanceFromRig = Local.GetPlayerDistanceFromRig(config, player)

		-- Player too far away, stop following and return to original position
		if distanceFromRig > config.attackDistance then
			Local.StopRig(config, animateEnemy)

			-- Wait for the enemy to return to its original position
			-- before allowing it to target another player
			if config.originalPosition then
				local returnDelay = 3 -- Give the enemy time to return
				task.wait(returnDelay)
			end

			return
		end

		-- Within the attack distance, move towards the player
		if distanceFromRig < config.attackDistance and distanceFromRig > -1 then
			Local.MoveRigToPlayer(config, player, platformBoundaries, animateEnemy)
			task.wait(0.2)
		end
	end
end

function Local.MoveRigToPlayer(config, player, platformBoundaries, animateEnemy)
	local targetPosition = player.Character.HumanoidRootPart.Position

	-- Check if the target position is within the platform boundaries
	if BoundaryUtil.IsPositionOnPlatform(targetPosition, platformBoundaries) then
		config.rig.Humanoid:MoveTo(targetPosition)
	else
		-- If target is off platform, move to the closest point on the platform
		local clampedPosition = Vector3.new(
			math.clamp(targetPosition.X, platformBoundaries.min.X, platformBoundaries.max.X),
			targetPosition.Y,
			math.clamp(targetPosition.Z, platformBoundaries.min.Z, platformBoundaries.max.Z)
		)

		config.rig.Humanoid:MoveTo(clampedPosition)
	end

	animateEnemy:play()
end

function Local.StopRig(config, animateEnemy)
	config.movingToPlayerId = nil

	-- Return to original position if it exists
	if config.originalPosition then
		config.rig.Humanoid:MoveTo(config.originalPosition)
	else
		-- Fallback to stopping in place if no original position is available
		config.rig.Humanoid:MoveTo(config.rig.HumanoidRootPart.Position)
	end

	animateEnemy:stop()
end

function Local.GetPlayerDistanceFromRig(config, player)
	local humanoidPosition = config.rig.HumanoidRootPart.Position
	local playerPosition = player.Character:FindFirstChild("HumanoidRootPart").Position
	return (playerPosition - humanoidPosition).Magnitude
end

return Shared
