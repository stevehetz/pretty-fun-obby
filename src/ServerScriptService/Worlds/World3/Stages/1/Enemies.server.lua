local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local EnemyUtil = require(ReplicatedStorage.Utils.EnemyUtil.EnemyUtil)

if not WorldsConfig.IsWorld("World3") then
	return
end

local Enemies = Workspace.Stages["1"].Enemies

if not Enemies then
	return
end

-- Keep track of enemy count to assign unique identifiers
local enemyCount = 0

for _, child in Enemies:GetChildren() do
	print("Child: ", child.Name)
	if child:IsA("Model") and child.Name == "Enemy" then
		-- Increment enemy count and assign a unique index
		enemyCount = enemyCount + 1
		child:SetAttribute("EnemyIndex", enemyCount)

		print("Setting up enemy " .. enemyCount)

		task.spawn(function()
			local config: EnemyUtil.EnemyUtilConfig = {
				rig = child,
				setPlatformBoundaries = true,
				damageAmount = 60,
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

print("Total enemies set up: " .. enemyCount)
