export type Trail = "Red Trail" | "Blue Trail" | "Green Trail" | "Rainbow Trail" | "RedBlueOrange Trail"

type TrailsConfig = {
	[Trail]: ColorSequence,
}

local Config: TrailsConfig = {
	["Red Trail"] = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(1, 1, 1)),
	["Blue Trail"] = ColorSequence.new(Color3.new(0, 0, 1), Color3.new(1, 1, 1)),
	["Green Trail"] = ColorSequence.new(Color3.new(0.4, 0.894117, 0.364705), Color3.new(1, 1, 1)),
	["Rainbow Trail"] = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.2, Color3.new(1, 0.5, 0)), -- Orange
		ColorSequenceKeypoint.new(0.4, Color3.new(1, 1, 0)), -- Yellow
		ColorSequenceKeypoint.new(0.6, Color3.new(0, 1, 0)), -- Green
		ColorSequenceKeypoint.new(0.8, Color3.new(0, 0, 1)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.new(0.5, 0, 1)), -- Purple
	}),
	["RedBlueOrange Trail"] = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)), -- Red
		ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 1)), -- Blue
		ColorSequenceKeypoint.new(1, Color3.new(1, 0.5, 0)), -- Orange
	}),
}

local Local = {}
local Shared = {}

Shared.Config = Config

function Shared.GetTrailColor(trail: Trail)
	return Shared.Config[trail]
end

return Shared
