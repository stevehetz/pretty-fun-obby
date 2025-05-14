local Local = {}
local Shared = {}

function Shared.GetBoundaryOfRig(rig, platform)
	-- Get the platform that the source is on
	if not platform then
		-- If no specific platform is found, try to find what the zombie is standing on
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = { rig }

		local raycastResult = workspace:Raycast(rig.HumanoidRootPart.Position, Vector3.new(0, -10, 0), raycastParams)
		if raycastResult and raycastResult.Instance then
			platform = raycastResult.Instance
			print("Detected platform:", platform:GetFullName())
		end
	end

	if platform then
		-- Define platform boundaries
		local platformBoundaries = {
			min = Vector3.new(-math.huge, -math.huge, -math.huge),
			max = Vector3.new(math.huge, math.huge, math.huge),
		}

		local platformSize = platform.Size
		local platformPosition = platform.Position
		local platformCFrame = platform.CFrame

		-- Calculate platform boundaries in world space
		local halfSize = platformSize / 2
		local cornerOffset = Vector3.new(halfSize.X, 0, halfSize.Z) -- Ignore Y to allow movement up/down on the platform

		-- Add a small margin to prevent the zombie from walking right on the edge
		local margin = 1
		cornerOffset = cornerOffset - Vector3.new(margin, 0, margin)

		-- Calculate min and max points in world space
		-- platformBoundaries.min = platformPosition - cornerOffset
		-- platformBoundaries.max = platformPosition + cornerOffset

		-- Check to make sure the boundaries are valid
		if platformBoundaries.min.X > platformBoundaries.max.X then
			platformBoundaries.min =
				Vector3.new(platformBoundaries.max.X, platformBoundaries.min.Y, platformBoundaries.min.Z)
		end
		if platformBoundaries.min.Z > platformBoundaries.max.Z then
			platformBoundaries.min =
				Vector3.new(platformBoundaries.min.X, platformBoundaries.min.Y, platformBoundaries.max.Z)
		end

		print("Platform boundaries set: Min =", platformBoundaries.min, "Max =", platformBoundaries.max)

		return platformBoundaries
	else
		print("No platform detected for rig:", rig:GetFullName())
		return nil
	end
end

-- Function to check if a position is within platform boundaries
function Shared.IsPositionOnPlatform(position, platformBoundaries)
	-- Always allow Y movement (up/down)
	return position.X >= platformBoundaries.min.X
		and position.X <= platformBoundaries.max.X
		and position.Z >= platformBoundaries.min.Z
		and position.Z <= platformBoundaries.max.Z
end

return Shared
