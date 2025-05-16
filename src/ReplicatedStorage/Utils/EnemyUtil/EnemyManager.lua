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

	-- Store original CFrames and clones of enemies for respawning
	local enemyOriginalCFrames = {}
	local enemyClones = {}

	-- Function to create an enemy at the specified CFrame
	local function createEnemy(enemyClone, originalCFrame)
		-- Clone the original enemy model
		local newEnemy = enemyClone:Clone()
		newEnemy.Parent = enemiesFolder

		-- Set the CFrame
		if newEnemy:FindFirstChild("HumanoidRootPart") then
			newEnemy.HumanoidRootPart.CFrame = originalCFrame
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
					originalPosition = originalCFrame.Position,
				}

				-- Set up death event for this new enemy
				newEnemy.Humanoid.Died:Connect(function()
					local originalCF = enemyOriginalCFrames[newEnemy.Name]

					-- Destroy the enemy
					newEnemy:Destroy()

					-- Recreate the enemy after 10 seconds
					task.delay(10, function()
						createEnemy(enemyClones[newEnemy.Name], originalCF)
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
			-- Store the original CFrame
			local name = child.Name .. "_" .. enemyCounter
			enemyCounter = enemyCounter + 1
			local originalCFrame = child.HumanoidRootPart.CFrame
			enemyOriginalCFrames[name] = originalCFrame

			-- Create a clone of the enemy and store it
			local enemyClone = child:Clone()
			enemyClone.Name = name
			enemyClones[name] = enemyClone

			child:Destroy()

			task.spawn(function()
				createEnemy(enemyClone, originalCFrame)
			end)
		end
	end

	-- Check for enemies falling off the platform
	-- Check for fallen enemies every 5 seconds instead of yielding on every heartbeat
	task.spawn(function()
		while true do
			task.wait(1)
			for _, enemy in pairs(enemiesFolder:GetChildren()) do
				if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
					-- Check if the enemy has fallen below the death Y-level
					if enemy.HumanoidRootPart.Position.Y < deathYLevel then
						-- Extract the base name (remove the unique ID suffix)

						local originalCFrame = enemyOriginalCFrames[enemy.Name]
						if originalCFrame then
							-- Destroy the enemy
							enemy:Destroy()

							-- Recreate the enemy after 10 seconds
							task.delay(10, function()
								createEnemy(enemyClones[enemy.Name], originalCFrame)
							end)
						end
					end
				end
			end
		end
	end)
end

return Shared
