local Workspace = game:GetService("Workspace")

local Local = {}
local Shared = {}

function Shared.GetTotalStages()
	local children = Workspace.Stages:GetChildren()
	return #children - 1 -- returns count of children
end

function Shared.GetSpawnlocation(stage: number)
	local stagesFolder: Folder = Workspace:WaitForChild("Stages")
	if not stagesFolder then
		return nil
	end

	local stageFolder: Folder = stagesFolder:FindFirstChild(tostring(stage))
	if not stageFolder then
		return nil
	end

	local spawnLocation = stageFolder:FindFirstChildOfClass("SpawnLocation")
	if not spawnLocation then
		spawnLocation = stageFolder:WaitForChild("SpawnLocation")
	end

	return spawnLocation
end

return Shared
