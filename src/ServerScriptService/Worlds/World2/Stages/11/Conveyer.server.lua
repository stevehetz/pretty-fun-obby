WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)

if not WorldsConfig.IsWorld("World2") then
	return
end

local part = game.Workspace.Stages["11"].Conveyer
part.AssemblyLinearVelocity = Vector3.new(-50, 0, 0)
