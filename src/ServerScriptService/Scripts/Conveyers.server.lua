local Workspace = game:GetService("Workspace")

local StagesFolder = Workspace.Stages
local DEFAULT_SPEED = 50 -- Speed magnitude in studs per second

-- Function to update conveyer platform velocity
for _, model in StagesFolder:GetDescendants() do
	if model:IsA("Model") and model.Name == "Conveyer" then
		local customSpeed = model:GetAttribute("Speed")
		local speed = customSpeed or DEFAULT_SPEED
		print("Conveyer speed:", speed)
		local platform = model:FindFirstChild("Platform")
		local target = model:FindFirstChild("Target")

		if platform and target then
			-- Calculate direction vector from platform to target
			local direction = (target.Position - platform.Position).Unit

			-- Set velocity in the direction of the target with the desired speed
			platform.AssemblyLinearVelocity = direction * speed
		end
	end
end
