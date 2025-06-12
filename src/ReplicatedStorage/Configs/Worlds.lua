export type WorldName = "World1" | "World2" | "World3" | "World4"

local PLACE_IDS = {
	["World1"] = 139398903012255,
	["World2"] = 71122824760185,
	["World3"] = 128199095645816,
	["World4"] = 76460924671569,
}

local DISPLAY_NAMES = {
	["World1"] = "World 1",
	["World2"] = "World 2",
	["World3"] = "World 3",
	["World4"] = "World 4",
}

local Local = {}
local Shared = {}

function Shared.IsWorld(worldName: string): boolean
	local currentPlaceId = game.PlaceId
	local placeId = PLACE_IDS[worldName]
	return placeId and currentPlaceId == placeId
end

function Shared.GetAllWorlds(): { WorldName }
	local worlds = {}

	for worldName, _ in pairs(PLACE_IDS) do
		worlds[worldName] = {
			Name = worldName,
			DisplayName = DISPLAY_NAMES[worldName] or worldName,
			PlaceId = PLACE_IDS[worldName],
		}
	end

	return worlds
end

function Shared.GetPlaceIdFromWorldName(worldName: WorldName): number?
	local placeId = PLACE_IDS[worldName]
	if not placeId then
		return nil
	end

	return placeId
end

function Shared.GetDisplayNameFromWorldName(worldName: WorldName): string?
	local displayName = DISPLAY_NAMES[worldName]
	if not displayName then
		return nil
	end

	return displayName
end

function Shared.GetCurrentWorldName(): WorldName?
	local placeId = game.PlaceId

	for worldName, id in pairs(PLACE_IDS) do
		if id == placeId then
			return worldName
		end
	end

	return nil
end

return Shared
