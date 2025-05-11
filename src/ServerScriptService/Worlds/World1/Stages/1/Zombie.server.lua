local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Zombie = Workspace.Rigs.Zombie
local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local EnemyUtil = require(ReplicatedStorage.Utils.EnemyUtil.EnemyUtil)

if not WorldsConfig.IsWorld("World1") then
	return
end

local config: EnemyUtil.EnemyUtilConfig = {
	rig = Zombie,
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
