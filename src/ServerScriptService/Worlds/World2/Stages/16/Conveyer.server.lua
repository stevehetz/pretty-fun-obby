local WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)

if not WorldsConfig.IsWorld("World2") then
	return
end

local part = game.Workspace.Stages["16"].Conveyer
part.AssemblyLinearVelocity = Vector3.new(0, 0, -50)
