local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemyManager = require(ReplicatedStorage.Utils.EnemyUtil.EnemyManager)

local StagesFolder = Workspace.Stages

for _, stageFolder in StagesFolder:GetChildren() do
	if stageFolder:IsA("Folder") then
		local enemiesFolder = stageFolder:FindFirstChild("Enemies")
		if enemiesFolder then
			task.spawn(function()
				EnemyManager.Load({
					enemiesFolder = enemiesFolder,
				})
			end)
		end
	end
end
