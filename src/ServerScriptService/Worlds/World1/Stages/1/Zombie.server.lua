local WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)
local BoundaryHelper = require(game.ReplicatedStorage.Utils.BoundaryHelper)
local EnemyHelper = require(game.ReplicatedStorage.Utils.EnemyHelper)

if not WorldsConfig.IsWorld("World1") then
	return
end

local config: EnemyHelper.EnemyHelperConfig = {
	rig = game.Workspace.Rigs.Zombie,
	platformBoundaries = BoundaryHelper.GetBoundaryOfRig(game.Workspace.Rigs.Zombie),
	damageAmount = 60,
	damageCooldown = 1,
	attackDistance = 50,
	animationAssetId = "rbxassetid://137589538429321",
	damageParts = {
		"LeftHand",
		"RightHand",
	},
}

EnemyHelper.EnableAttack(config)
