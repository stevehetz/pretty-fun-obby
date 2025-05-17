local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemyManager = require(ReplicatedStorage.Utils.EnemyUtil.EnemyManager)

local StagesFolder = Workspace.Stages

for _, stageFolder in StagesFolder:GetChildren() do
	if stageFolder:IsA("Folder") then
		for _, enemiesFolder in stageFolder:GetChildren() do
			if enemiesFolder:IsA("Folder") and enemiesFolder.Name == "Enemies" then
				-- Load the enemies for this stage
				task.spawn(function()
					EnemyManager.Load({
						enemiesFolder = enemiesFolder,
					})
				end)
			end
		end
	end
end
