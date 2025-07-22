local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local TrailsConfig = require(ReplicatedStorage.Configs.Trails)

local Player = Players.LocalPlayer

local Local = {}
local Shared = {}

function Shared.OnStart()
	local character = Player.Character or Player.CharacterAdded:Wait()
	if character then
		local part = character:WaitForChild("HumanoidRootPart")
		-- Local.AddTrail(part, Local.Trails["RedBlueOrange"])
	end

	Player.CharacterAdded:Connect(function(character)
		local part = character:WaitForChild("HumanoidRootPart")
	end)
end

function Shared.AddTrail(part, trailColorSeq)
	local att0 = Instance.new("Attachment", part)
	att0.Position = Vector3.new(0, 2, 0)

	local att1 = Instance.new("Attachment", part)
	att1.Position = Vector3.new(0, -2, 0)

	local trail = Instance.new("Trail", part)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.4
	trail.WidthScale = NumberSequence.new(1)
	trail.Color = trailColorSeq
end

return Shared
