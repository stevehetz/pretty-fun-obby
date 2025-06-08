local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local EnemyUtil = require(ReplicatedStorage.Utils.EnemyUtil.EnemyUtil)
local Sounds = require(ReplicatedStorage.Configs.Sounds)

-- Create a RemoteEvent for playing sounds only for specific players
local PlaySoundEvent = Instance.new("RemoteEvent")
PlaySoundEvent.Name = "PlayTrashcanSoundEvent"
PlaySoundEvent.Parent = ReplicatedStorage

local Local = {}
local Shared = {}

function Shared.SetupTrashcan(player, trashcan)
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		return
	end

	local db = 0

	trashcan.Activated:Connect(function()
		local player = game.Players:GetPlayerFromCharacter(trashcan.Parent)
		local trashcanParts = trashcan.TrashcanParts

		if db == 0 then
			db = 1

			local char = player.Character
			local humanoid = char:FindFirstChild("HumanoidRootPart")

			task.wait(0.3)

			for _, p in pairs(trashcanParts:GetChildren()) do
				p.Transparency = 1
			end

			local clone = ReplicatedStorage.Throwables.TrashCan:Clone()
			clone.Parent = game.Workspace
			clone.Material = Enum.Material.Metal

			-- Set up custom physical properties for better physics interaction
			clone.CustomPhysicalProperties = PhysicalProperties.new(
				50, -- density
				0.3, -- friction
				0.5 -- elasticity
			)

			-- Calculate a point 4 studs in front of the HRP, and 4 studs above
			local forwardDistance = 5
			local heightOffset = 3
			local spawnPosition = humanoid.Position
				+ humanoid.CFrame.LookVector * forwardDistance
				+ Vector3.new(0, heightOffset, 0)

			-- Place the part at spawnPosition
			clone.CFrame = CFrame.new(spawnPosition)
			-- Rotate so that its front faces the same direction as the player,
			-- plus the 270° X-rotation you had originally
			clone.Orientation = humanoid.Orientation + Vector3.new(270, 0, 0)

			clone.AssemblyLinearVelocity = humanoid.CFrame.LookVector * 150 + Vector3.new(0, 0.8, 0)

			-- Set up collision detection with enemies
			local hitEnemies = {} -- Track which enemies have been hit to prevent multiple hits

			-- Connect to the Touched event to detect collisions with enemies
			clone.Touched:Connect(function(hit)
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
						local impactDir = (hrp.Position - clone.Position).Unit

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
							-- Get the player who threw the trashcan
							local throwerPlayer = player
							-- Fire the RemoteEvent only to the player who threw the trashcan
							PlaySoundEvent:FireClient(throwerPlayer, "Dink")
						end)
					end
				end
			end)

			-- Fade out and remove the thrown trashcan after 7 seconds
			task.delay(7, function()
				-- Create a tween to fade out the trashcan
				local tweenInfo = TweenInfo.new(
					1, -- Duration (1 second fade)
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				)

				local transparencyGoal = { Transparency = 1 }
				local tween = tweenService:Create(clone, tweenInfo, transparencyGoal)
				tween:Play()

				-- Remove the trashcan after the tween completes
				tween.Completed:Connect(function()
					clone:Destroy()
				end)
			end)

			task.wait(1)

			for _, p in pairs(trashcanParts:GetChildren()) do
				p.Transparency = 0
			end

			db = 0
		end
	end)
end

return Shared
