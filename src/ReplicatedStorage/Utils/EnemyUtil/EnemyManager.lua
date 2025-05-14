local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyUtil = require(ReplicatedStorage.Utils.EnemyUtil.EnemyUtil)

export type EnemyManagerConfig = {
	enemiesFolder: Folder,
}

local Local = {}
local Shared = {}

function Shared.Load(config: EnemyManagerConfig)
	local enemiesFolder = config.enemiesFolder

	-- Keep track of enemy count to assign unique identifiers
	local enemyCount = 0

	-- Store original positions of enemies for respawning
	local enemyOriginalPositions = {}

	-- Function to respawn an enemy at its original position
	local function respawnEnemy(enemy, originalPosition)
		if not enemy or not enemy:FindFirstChild("HumanoidRootPart") or not enemy:FindFirstChild("Humanoid") then
			return
		end

		-- Reset the enemy's position
		enemy.HumanoidRootPart.CFrame = CFrame.new(originalPosition)
		enemy.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
		enemy.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)

		-- Reset the enemy's humanoid
		enemy.Humanoid.Health = enemy.Humanoid.MaxHealth
		enemy.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

		print("Respawned enemy at original position")
	end

	-- Find the EnemyPlatform part to use as the boundary
	local enemyPlatform = enemiesFolder:FindFirstChild("EnemyPlatform")

	-- Determine the death Y-level (slightly below the platform)
	local deathYLevel = enemyPlatform and (enemyPlatform.Position.Y - 10) or -50

	for _, child in enemiesFolder:GetChildren() do
		print("Child: ", child.Name)
		if child:IsA("Model") then
			-- Increment enemy count and assign a unique index
			enemyCount = enemyCount + 1
			child:SetAttribute("EnemyIndex", enemyCount)

			print("Setting up enemy " .. enemyCount)

			-- Store the original position for respawning
			if child:FindFirstChild("HumanoidRootPart") then
				enemyOriginalPositions[child] = child.HumanoidRootPart.Position
			end

			task.spawn(function()
				local config: EnemyUtil.EnemyUtilConfig = {
					rig = child,
					setPlatformBoundaries = true,
					platform = enemyPlatform, -- Pass the platform to use as boundary
					damageAmount = 2,
					damageCooldown = 1,
					attackDistance = 50,
					animationAssetId = "rbxassetid://137589538429321",
					damageParts = {
						"LeftHand",
						"RightHand",
					},
				}

				EnemyUtil.EnableAttack(config)
			end)
		end
	end

	-- Check for enemies falling off the platform
	RunService.Heartbeat:Connect(function()
		for enemy, originalPosition in pairs(enemyOriginalPositions) do
			if enemy and enemy:FindFirstChild("HumanoidRootPart") then
				-- Check if the enemy has fallen below the death Y-level
				if enemy.HumanoidRootPart.Position.Y < deathYLevel then
					respawnEnemy(enemy, originalPosition)
				end
			end
		end
	end)

	print("Total enemies set up: " .. enemyCount)
end

return Shared
