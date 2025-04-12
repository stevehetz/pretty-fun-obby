local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local StateController = require(script.Parent.StateController)
local GuiController = require(script.Parent.GuiController)	
local StagesConfig = require(ReplicatedStorage.Configs.Stages)

local Gui = GuiController.BillboardGuis.StageArrow

local Local = {}
local Shared = {}

Local.ActiveGui = nil

function Shared.OnStart()
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction, state: StateController.PlayerData)
		if action.type == "UpdateStage" then
			Local.DisplayArrow()
			Local.HighlightPart(state.stage)
		end
	end)

	Local.DisplayArrow()
end

function Local.HighlightPart(stage: number)
	local folder = Workspace.Stages[stage]
	local checkpoint = folder:WaitForChild("Checkpoint", 2)
	if not checkpoint then
		return
	end

	local checkpointArrow: Part = checkpoint:WaitForChild("Arrow", 2)
	checkpointArrow.Material = Enum.Material.Neon
	checkpointArrow.Color = Color3.fromRGB(0, 255, 0)
	checkpointArrow.Transparency = 0.25

	-- wait for 2 seconds
	task.wait(2)
	checkpointArrow.Material = Enum.Material.SmoothPlastic
	checkpointArrow.Color = Color3.fromRGB(255, 255, 255)
	checkpointArrow.Transparency = 0
end

function Local.DisplayArrow()
	local nextStage = StateController.GetState().stage + 1

	local spawnLocation = StagesConfig.GetSpawnlocation(nextStage)
	if not spawnLocation then
		return
	end

	if Local.ActiveGui then
		Local.ActiveGui:Destroy()
	end

	local clone = Gui:Clone()
	clone.Enabled = true
	clone.Parent = spawnLocation
	Local.ActiveGui = clone

	local tweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 5, true)
	local tweenProps = {}
	tweenProps.StudsOffset = Vector3.new(0, 7.5, 0)
	local tween = TweenService:Create(clone, tweenInfo, tweenProps)
	tween:Play()

	tween.Completed:Connect(function()
		clone:Destroy()
	end)
end

return Shared
