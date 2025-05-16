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

	-- Store original positions and clones of enemies for respawning
	local enemyOriginalPositions = {}
	local enemyOriginalOrientations = {}
	local enemyClones = {}

	-- Function to create an enemy at the specified position
	local function createEnemy(enemyClone, position, orientation)
		-- Clone the original enemy model
		local newEnemy = enemyClone:Clone()
		newEnemy.Parent = enemiesFolder

		-- Set the position
		if newEnemy:FindFirstChild("HumanoidRootPart") then
			-- set just the position
			newEnemy.HumanoidRootPart.CFrame = CFrame.new(position)
			newEnemy.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
			newEnemy.HumanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
		end

		-- Set up the enemy with EnemyUtil
		task.spawn(function()
			if newEnemy:FindFirstChild("HumanoidRootPart") and newEnemy:FindFirstChild("Humanoid") then
				local config: EnemyUtil.EnemyUtilConfig = {
					rig = newEnemy,
					setPlatformBoundaries = true,
					platform = enemiesFolder:FindFirstChild("EnemyPlatform"),
					walkSpeed = 23,
					damageAmount = 10,
					damageCooldown = 1,
					attackDistance = 50,
					animationAssetId = "rbxassetid://95135060939003",
					damageParts = {
						"LeftLowerLeg",
						"RightLowerLeg",
					},
					originalPosition = position,
				}

				-- Set up death event for this new enemy
				newEnemy.Humanoid.Died:Connect(function()
					local originalPos = position
					local originalOrientation = orientation

					-- Destroy the enemy
					newEnemy:Destroy()

					-- Recreate the enemy after 10 seconds
					task.delay(10, function()
						createEnemy(enemyClones[newEnemy.Name], originalPos, originalOrientation)
					end)
				end)

				EnemyUtil.EnableAttack(config)
			end
		end)

		return newEnemy
	end

	-- Find the EnemyPlatform part to use as the boundary
	local enemyPlatform = enemiesFolder:FindFirstChild("EnemyPlatform")

	-- Determine the death Y-level (slightly below the platform)
	local deathYLevel = enemyPlatform and (enemyPlatform.Position.Y - 10) or -50

	local enemyCounter = 0

	-- First, create clones of all enemies
	for _, child in enemiesFolder:GetChildren() do
		if child:IsA("Model") and child:FindFirstChild("HumanoidRootPart") and child:FindFirstChild("Humanoid") then
			-- Store the original position
			local name = child.Name .. "_" .. enemyCounter
			enemyCounter = enemyCounter + 1
			local originalPosition = child.HumanoidRootPart.Position
			enemyOriginalPositions[name] = originalPosition
			local originalOrientation = child.HumanoidRootPart.CFrame
			enemyOriginalOrientations[name] = originalOrientation

			-- Create a clone of the enemy and store it
			local enemyClone = child:Clone()
			enemyClone.Name = name
			enemyClones[name] = enemyClone

			child:Destroy()

			task.spawn(function()
				createEnemy(enemyClone, originalPosition, originalOrientation)
			end)
		end
	end

	-- Check for enemies falling off the platform
	RunService.Heartbeat:Connect(function()
		task.wait(5)
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
				-- Check if the enemy has fallen below the death Y-level
				if enemy.HumanoidRootPart.Position.Y < deathYLevel then
					-- Extract the base name (remove the unique ID suffix)

					local originalPosition = enemyOriginalPositions[enemy.Name]
					local originalOrientation = enemyOriginalOrientations[enemy.Name]
					if originalPosition then
						-- Destroy the enemy
						enemy:Destroy()

						-- Recreate the enemy after 10 seconds
						task.delay(10, function()
							createEnemy(enemyClones[enemy.Name], originalPosition, originalOrientation)
						end)
					end
				end
			end
		end
	end)
end

return Shared
