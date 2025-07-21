local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer

local Local = {}
local Shared = {}

Local.Trails = {
	["Green"] = {
		ColorSequence = ColorSequence.new(Color3.new(0.4, 0.894117, 0.364705), Color3.new(1, 1, 1)),
		Width = 1,
		Lifetime = 0.4,
	},
	["Red"] = {
		ColorSequence = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(1, 1, 1)),
		Width = 1,
		Lifetime = 0.4,
	},
	["Blue"] = {
		ColorSequence = ColorSequence.new(Color3.new(0, 0, 1), Color3.new(1, 1, 1)),
		Width = 1,
		Lifetime = 0.4,
	},
	["Rainbow"] = {
		ColorSequence = ColorSequence.new(
			Color3.new(1, 0, 0),
			Color3.new(1, 0.5, 0),
			Color3.new(1, 1, 0),
			Color3.new(0, 1, 0),
			Color3.new(0, 0, 1),
			Color3.new(0.5, 0, 1)
		),
		Width = 1,
		Lifetime = 0.4,
	},
}

function Shared.OnStart()
	local character = Player.Character or Player.CharacterAdded:Wait()
	if character then
		local part = character:WaitForChild("HumanoidRootPart")
		Local.AddTrail(part, Local.Trails["Rainbow"])
	end

	Player.CharacterAdded:Connect(function(character)
		local part = character:WaitForChild("HumanoidRootPart")
		Local.AddTrail(part, Local.Trails["Rainbow"])
	end)

	-- Setup item displays
	Local.SetupItemDisplays()
end

Local.SetupItemDisplays = function()
	task.wait(1) -- Wait for item displays to load
	local ItemDisplaysFolder = Workspace:WaitForChild("ItemDisplays")
	if not ItemDisplaysFolder then
		warn("ItemDisplays folder not found in Workspace")
		return
	end

	-- Iterate through all ItemDisplays, find any with TrailDisplay as a child
	for _, itemDisplay in ipairs(ItemDisplaysFolder:GetChildren()) do
		if itemDisplay:IsA("Model") and itemDisplay:FindFirstChild("TrailDisplay") then
			if itemDisplay.Name == "GreenRibbon" then
				-- Use the green trail for GreenRibbon
				Local.SetupTrailDisplayPart(itemDisplay.TrailDisplay, Local.Trails["Green"])
			elseif itemDisplay.Name == "RedRibbon" then
				-- Use the red trail for RedRibbon
				Local.SetupTrailDisplayPart(itemDisplay.TrailDisplay, Local.Trails["Red"])
			elseif itemDisplay.Name == "BlueRibbon" then
				-- Use the blue trail for BlueRibbon
				Local.SetupTrailDisplayPart(itemDisplay.TrailDisplay, Local.Trails["Blue"])
			elseif itemDisplay.Name == "RainbowRibbon" then
				-- Use the rainbow trail for RainbowRibbon
				Local.SetupTrailDisplayPart(itemDisplay.TrailDisplay, Local.Trails["Rainbow"])
			end
		end
	end
end

Local.SetupTrailDisplayPart = function(part, trailConfig)
	part.Transparency = 1

	-- Add trail to the part
	Local.AddTrail(part, trailConfig)

	-- Get the parent ItemDisplay to determine orientation
	local itemDisplay = part.Parent
	if not itemDisplay then
		warn("TrailDisplay part has no parent")
		return
	end

	-- Calculate the right vector (side-to-side direction) based on the itemDisplay's orientation
	local rightVector = itemDisplay.NamePlate.CFrame.RightVector * 5 -- Scale for movement distance

	-- Start position (5 units up, and offset in the opposite direction of movement)
	part.Position = part.Position + Vector3.new(0, 5, 0) - rightVector

	-- Move part back and forth along the right vector (side to side relative to display orientation)
	local tweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)
	local goal = { Position = part.Position + rightVector * 2 } -- Move in the right direction
	local tween = tweenService:Create(part, tweenInfo, goal)
	tween:Play()
end

function Local.AddTrail(part, trailConfig)
	local att0 = Instance.new("Attachment", part)
	att0.Position = Vector3.new(0, 2, 0)

	local att1 = Instance.new("Attachment", part)
	att1.Position = Vector3.new(0, -2, 0)

	local trail = Instance.new("Trail", part)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = trailConfig.Lifetime
	trail.WidthScale = NumberSequence.new(trailConfig.Width)
	trail.Color = trailConfig.ColorSequence
end

return Shared
