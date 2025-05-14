local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local EnemyManager = require(ReplicatedStorage.Utils.EnemyUtil.EnemyManager)

if not WorldsConfig.IsWorld("World3") then
	return
end

local StagesFolder = Workspace.Stages

for _, stageFolder in StagesFolder:GetChildren() do
	if stageFolder:IsA("Folder") then
		local enemiesFolder = stageFolder:FindFirstChild("Enemies")
		if enemiesFolder then
			task.spawn(function()
				print("loading enemies for stage: " .. stageFolder.Name)
				EnemyManager.Load({
					enemiesFolder = enemiesFolder,
				})
			end)
		end
	end
end
