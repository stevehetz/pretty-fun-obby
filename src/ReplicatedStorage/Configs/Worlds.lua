export type WorldName = "World1" | "World2"

local PLACE_IDS = {
	["World1"] = 139398903012255,
	["World2"] = 71122824760185,
}

local DISPLAY_NAMES = {
	["World1"] = "World 1",
	["World2"] = "World 2",
}

local Local = {}
local Shared = {}

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
