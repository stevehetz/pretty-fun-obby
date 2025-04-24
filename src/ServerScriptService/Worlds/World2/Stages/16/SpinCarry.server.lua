local part = game.Workspace.Stages["16"].SpinCarry

local originalOrientation = part.Orientation
local originalPosition = part.Position

-- Create attachment first
local attachment = Instance.new("Attachment", part)

-- Create AlignPosition with the name "AlignPosition"
local alignPosition = Instance.new("AlignPosition", part)
alignPosition.Name = "AlignPosition"
alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
alignPosition.Position = part.Position
alignPosition.Attachment0 = attachment
alignPosition.MaxVelocity = 10
alignPosition.MaxForce = 1000000

local alignOrientation = Instance.new("AlignOrientation", part)
alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
alignOrientation.Attachment0 = attachment
alignOrientation.Responsiveness = 50 -- Adjust this value to control how quickly it reaches the target orientation
alignOrientation.RigidityEnabled = true -- Makes the orientation more stable

-- Initial orientation
local currentRotation = 0
local resetting = false

while task.wait(0.01) do -- Small wait time for smooth rotation
	if resetting then
		return
	end

	-- Increment rotation angle
	currentRotation = currentRotation + 1
	-- Add a 2-stud buffer to the position comparison
	local positionDifference = (originalPosition - part.Position).Magnitude
	if positionDifference > 2 then
		resetting = true
		task.wait(5)
		part.Position = originalPosition
		part.Orientation = originalOrientation
		resetting = false
	end
	if currentRotation >= 360 then
		currentRotation = 0
	end

	-- Convert degrees to radians for CFrame
	local radians = math.rad(currentRotation)

	-- Set the target orientation using CFrame angles
	alignOrientation.CFrame = CFrame.fromEulerAnglesYXZ(0, radians, 0)
end
