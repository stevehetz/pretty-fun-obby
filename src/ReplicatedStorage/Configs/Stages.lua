local Workspace = game:GetService("Workspace")

local Local = {}
local Shared = {}

function Shared.GetTotalStages()
	local children = Workspace.Stages:GetChildren()
	return #children -- returns count of children
end

function Shared.GetSpawnlocation(stage: number)
	local stageFolder: Folder = Workspace.Stages[stage]
	local spawnLocation = stageFolder:FindFirstChildOfClass("SpawnLocation")
	if not spawnLocation then
		spawnLocation = stageFolder:WaitForChild("SpawnLocation")
	end

	return spawnLocation
end

return Shared
