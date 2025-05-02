local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local playerPets = Workspace:WaitForChild("PlayerPets")
local petOffset = CFrame.new(4, 1, 4)
local hoverSpeed = 3
local hoverSize = 0.5

RunService.RenderStepped:Connect(function(deltaTime)
	for _, folder in playerPets:GetChildren() do
		if not folder or not folder:IsA("Folder") then
			continue
		end
		for _, pet in folder:GetChildren() do
			if not pet or not pet:IsA("Model") or not pet.PrimaryPart then
				continue
			end
			local playerName = folder.Name
			local character = Workspace:FindFirstChild(playerName)

			if character == nil or not character:FindFirstChild("HumanoidRootPart") then
				continue
			end

			local goalCFrame = character.PrimaryPart.CFrame
				* petOffset
				* CFrame.new(0, math.sin(tick() * hoverSpeed) * hoverSize, 0)

			pet:PivotTo(pet.PrimaryPart.CFrame:Lerp(goalCFrame, 0.1))
		end
	end
end)
