-- WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)

-- local placeId = game.PlaceId
-- local worldName = "World2" -- This should be set based on the game context
-- local worldPlaceId = WorldsConfig.GetPlaceIdFromWorldName(worldName)

-- if placeId == worldPlaceId then
-- 	local part = game.Workspace.Stages["9"].Carry
-- 	local spawnPart = game.Workspace.Stages["9"].SpawnLocation

-- 	local originalOrientation = part.Orientation
-- 	local originalPosition = part.Position
-- 	local targetSizeX = part.Size.X
-- 	local targetPosition = Vector3.new(spawnPart.Position.X + targetSizeX, originalPosition.Y, spawnPart.Position.Z)

-- 	while true do
-- 		part.AlignPosition.Position = targetPosition
-- 		task.wait(7)

-- 		part.AlignPosition.Position = originalPosition
-- 		task.wait(7)

-- 		-- reset
-- 		part.Position = originalPosition
-- 		part.Orientation = originalOrientation
-- 	end
-- end
