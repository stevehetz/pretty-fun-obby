WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)

local placeId = game.PlaceId
local worldName = "World2" -- This should be set based on the game context
local worldPlaceId = WorldsConfig.GetPlaceIdFromWorldName(worldName)

if placeId == worldPlaceId then
	-- Get references to all trampolines in stage 18
	local stage = game.Workspace.Stages["18"]
	local trampolines = {}

	-- Find all trampolines in the stage
	for _, obj in pairs(stage:GetChildren()) do
		if obj.Name == "Trampoline" then
			table.insert(trampolines, obj)
		end
	end

	-- Set up each trampoline
	for _, trampoline in ipairs(trampolines) do
		-- Set the inner part's velocity (keep existing behavior)
		local innerPart = trampoline:FindFirstChild("Inner")
		if innerPart then
			innerPart.AssemblyLinearVelocity = Vector3.new(0, 250, 0)
		end
	end
end
