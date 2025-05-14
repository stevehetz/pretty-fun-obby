local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local EnemyManager = require(ReplicatedStorage.Utils.EnemyUtil.EnemyManager)

if not WorldsConfig.IsWorld("World3") then
	return
end

local EnemiesFolder = Workspace.Stages["1"].Enemies

if not EnemiesFolder then
	return
end

EnemyManager.Load({
	enemiesFolder = EnemiesFolder,
})
