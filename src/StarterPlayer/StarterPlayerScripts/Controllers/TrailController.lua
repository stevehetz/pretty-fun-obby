local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local TrailsConfig = require(ReplicatedStorage.Configs.Trails)
local StateController = require(script.Parent.StateController)

local Player = Players.LocalPlayer

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.RefreshPlayerTrail()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateEquippedTrails" then
			print("TrailController - UpdateEquippedTrails action received:", action.trailName)
			Local.RefreshPlayerTrail()
		end
	end)
end

function Local.RefreshPlayerTrail()
	print("TrailController - RefreshPlayerTrail called")
	local part = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
	if part then
		local state = StateController.GetState()
		if not state then
			return
		end

		state.equippedTrails = state.equippedTrails or {}

		print("TrailController - Equipped Trails:", state.equippedTrails)

		if state.equippedTrails == {} then
			Shared.RemoveTrail(part)
			return
		end

		for trailName, _ in pairs(state.equippedTrails) do
			local trailColorSeq = TrailsConfig.GetTrailColor(trailName)
			if trailColorSeq then
				print("TrailController - Adding trail:", trailName)
				Shared.AddTrail(part, trailColorSeq)
			else
				print("TrailController - No color found for trail:", trailName)
			end
		end
	end
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

function Shared.RemoveTrail(part)
	print("Removing trail from part:", part.Name)
	local trail = part:FindFirstChildOfClass("Trail")
	if trail then
		trail:Destroy()
	end

	local att0 = part:FindFirstChild("Attachment0")
	if att0 then
		att0:Destroy()
	end

	local att1 = part:FindFirstChild("Attachment1")
	if att1 then
		att1:Destroy()
	end
end

return Shared
