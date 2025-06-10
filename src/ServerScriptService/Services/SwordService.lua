local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local EnemyUtil = require(ReplicatedStorage.Utils.EnemyUtil.EnemyUtil)
local Sounds = require(ReplicatedStorage.Configs.Sounds)

-- Create a RemoteEvent for playing sounds only for specific players
local PlaySoundEvent = Instance.new("RemoteEvent")
PlaySoundEvent.Name = "PlaySwordSoundEvent"
PlaySoundEvent.Parent = ReplicatedStorage

local Local = {}
local Shared = {}

function Shared.SetupSword(player, sword)
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		return
	end

	local swordParts = sword.SwordParts
	local hitBox = swordParts:FindFirstChild("HitBox")

	-- Set up custom physical properties for better physics interaction
	hitBox.CustomPhysicalProperties = PhysicalProperties.new(
		50, -- density
		0.3, -- friction
		0.5 -- elasticity
	)

	-- Set up collision detection with enemies
	local hitEnemies = {} -- Track which enemies have been hit to prevent multiple hits

	-- Connect to the Touched event to detect collisions with enemies
	hitBox.Touched:Connect(function(hit)
		if hitBox.CanCollide == false then
			return
		end

		-- Check if the hit part belongs to an enemy
		local enemyModel = hit:FindFirstAncestorOfClass("Model")

		if
			enemyModel
			and enemyModel.Parent.Name == "Enemies"
			and enemyModel:FindFirstChild("Humanoid")
			and not hitEnemies[enemyModel]
		then
			-- Mark this enemy as hit to prevent multiple hits from the same trashcan
			hitEnemies[enemyModel] = true

			-- Apply a physical impact to the enemy
			if enemyModel:FindFirstChild("HumanoidRootPart") then
				local hrp = enemyModel.HumanoidRootPart

				-- Calculate impact direction (from trashcan to enemy)
				local impactDir = (hrp.Position - hitBox.Position).Unit

				-- Apply an impulse in that direction
				hrp:ApplyImpulse(impactDir * 5000)

				-- If no configuration found, create a temporary one
				local config = {
					rig = enemyModel,
					isKnockedOver = false,
				}

				-- Knock over the enemy
				EnemyUtil.KnockOver(config)

				-- Play a hit sound only for the player who threw the trashcan
				pcall(function()
					-- Fire the RemoteEvent only to the player who threw the trashcan
					PlaySoundEvent:FireClient(player, "Dink")
				end)
			end
		end
	end)

	sword.Activated:Connect(function()
		-- Clear the hitEnemies table so we can hit the same enemies again
		hitEnemies = {}

		hitBox.CanCollide = true

		task.wait(1)
		hitBox.CanCollide = false
	end)
end

return Shared
