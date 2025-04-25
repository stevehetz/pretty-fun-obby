WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)

local placeId = game.PlaceId
local worldName = "World2" -- This should be set based on the game context
local worldPlaceId = WorldsConfig.GetPlaceIdFromWorldName(worldName)

if placeId == worldPlaceId then
	local part = game.Workspace.Stages["29"].Conveyer
	part.AssemblyLinearVelocity = Vector3.new(-100, 0, 0)
end
