export type WorldName = "World1" | "World2" | "World3" | "World4"

local WORLDS = {
	{
		Name = "World1",
		DisplayName = "World 1",
		PlaceId = 139398903012255,
	},
	{
		Name = "World2",
		DisplayName = "World 2",
		PlaceId = 71122824760185,
	},
	{
		Name = "World3",
		DisplayName = "World 3",
		PlaceId = 128199095645816,
	},
	{
		Name = "World4",
		DisplayName = "World 4",
		PlaceId = 76460924671569,
	},
}

-- Create lookup tables for faster access
local WorldsByName = {}
for _, world in ipairs(WORLDS) do
	WorldsByName[world.Name] = world
end

local Local = {}
local Shared = {}

function Shared.IsWorld(worldName: string): boolean
	local currentPlaceId = game.PlaceId
	local world = WorldsByName[worldName]
	return world and currentPlaceId == world.PlaceId
end

function Shared.GetPlaceIdFromWorldName(worldName: WorldName): number?
	local world = WorldsByName[worldName]
	if not world then
		return nil
	end

	return world.PlaceId
end

function Shared.GetDisplayNameFromWorldName(worldName: WorldName): string?
	local world = WorldsByName[worldName]
	if not world then
		return nil
	end

	return world.DisplayName
end

function Shared.GetCurrentWorldName(): WorldName?
	local placeId = game.PlaceId

	for _, world in ipairs(WORLDS) do
		if world.PlaceId == placeId then
			return world.Name
		end
	end

	return nil
end

-- Expose the WORLDS table for direct access
Shared.WORLDS = WORLDS

return Shared
