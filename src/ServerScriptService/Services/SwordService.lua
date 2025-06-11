local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnemyUtil = require(ReplicatedStorage.Utils.EnemyUtil.EnemyUtil)

local Remotes = ReplicatedStorage.Remotes

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

	hitBox.Massless = true

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
			-- Mark this enemy as hit to prevent multiple hits from the same sword
			hitEnemies[enemyModel] = true

			-- Use the centralized function to knock over the enemy with 5 second recovery
			local config = EnemyUtil.KnockOverEnemy(enemyModel, hitBox, 15000, 5)

			-- Play a hit sound only for the player who used the sword
			pcall(function()
				-- Fire the RemoteEvent only to the player who used the sword
				Remotes.PlaySound:FireClient(player, "Dink")
			end)
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
