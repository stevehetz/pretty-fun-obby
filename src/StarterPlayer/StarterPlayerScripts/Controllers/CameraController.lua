local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera

local Shared = {}

-- Function to point camera in the direction the character is facing
function Shared.PointCamera(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then
		warn("HumanoidRootPart not found in character.")
		return
	end

	task.wait(0.1)
	local cameraDistance = 10 -- How far behind the character the camera should be
	local cameraHeight = 5 -- Upward offset for the camera

	local forward = hrp.CFrame.LookVector
	local cameraPosition = hrp.Position - forward * cameraDistance + Vector3.new(0, cameraHeight, 0)
	local newCameraCFrame = CFrame.new(cameraPosition, hrp.Position)

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = newCameraCFrame

	task.wait(0.1)
	camera.CameraType = Enum.CameraType.Custom
end

return Shared
