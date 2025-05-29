local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local SettingsConfig = require(ReplicatedStorage.Configs.Settings)
local SoundsConfig = require(ReplicatedStorage.Configs.Sounds)
local StateController = require(script.Parent.StateController)

local BlurEffect = Instance.new("BlurEffect", Lighting)
BlurEffect.Size = 0

local ALWAYS_ENABLED_GUIS = {
	"Top",
	"TopTwo",
	"Left",
	"Right",
}

local Local = {}
local Shared = {}

Shared.BillboardGuis = {
	StageArrow = PlayerGui:WaitForChild("StageArrow"),
}

Shared.Guis = {
	Top = PlayerGui:WaitForChild("Top"),
	TopTwo = PlayerGui:WaitForChild("TopTwo"),
	Left = PlayerGui:WaitForChild("Left"),
	Right = PlayerGui:WaitForChild("Right"),
	Setting = PlayerGui:WaitForChild("Settings"),
	Skips = PlayerGui:WaitForChild("Skips"),
	Rebirth = PlayerGui:WaitForChild("Rebirth"),
	Shop = PlayerGui:WaitForChild("Shop"),
	Worlds = PlayerGui:WaitForChild("Worlds"),
}

function Shared.OnStart()
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateSetting" and action.setting == "Menu Blur" then
			Shared.ToggleBlurEffect(action.value)
		end
	end)
end

function Shared.HandleProgressBar(progressBar: CanvasGroup, progressAmount: number, progressText: string?)
	local progressFrame: Frame = progressBar:FindFirstChild("Progress") or progressBar:FindFirstChildOfClass("Frame")
	if progressFrame and progressFrame:IsA("Frame") then
		local percent = math.clamp(progressAmount, 0, 1)
		local newSize = UDim2.fromScale(percent, 1)

		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local tweenGoal = {}
		tweenGoal.Size = newSize

		local tween = TweenService:Create(progressFrame, tweenInfo, tweenGoal)
		tween:Play()
	end

	local textLabel = progressBar:FindFirstChild("Amount" or progressBar:FindFirstChildOfClass("TextLabel"))
	if progressText and textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = progressText
	end
end

-- this is the most confusing way to do this omg
--- isGuiActive takes on multiple meanings depending where it comes from
function Shared.ToggleBlurEffect(isGuiActive: boolean)
	local isSettingEnabled = SettingsConfig.GetSettingValue(StateController.GetState(), "Menu Blur")
	if isGuiActive and not isSettingEnabled then
		return
	end

	local targetSize = if isGuiActive then 14 else 0

	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local tweenGoal = {}
	tweenGoal.Size = targetSize

	local tween = TweenService:Create(BlurEffect, tweenInfo, tweenGoal)
	tween:Play()
end

function Shared.SetupGui(gui: ScreenGui, openButton: TextButton?, exitButton: TextButton?)
	exitButton = exitButton or gui:FindFirstChild("Exit", true)

	if openButton then
		openButton.MouseButton1Click:Connect(function()
			SoundsConfig.PlaySound("Menu-Click")
			Shared.ToggleGui(gui)
		end)
	else
		print("No open button found for " .. gui.Name)
	end

	if exitButton then
		exitButton.MouseButton1Click:Connect(function()
			SoundsConfig.PlaySound("Menu-Click")
			Shared.ToggleGui(gui)
		end)
	end
end

function Shared.ToggleGui(gui: ScreenGui)
	Shared.ToggleBlurEffect(not gui.Enabled)
	if gui.Enabled then
		Local.AnimateFrame(gui.Frame, false)
		return
	end

	Local.AnimateFrame(gui.Frame, true)

	gui.Enabled = true
	Local.HideGui(gui)
end

function Local.HideGui(gui: ScreenGui)
	for _, screenGui in PlayerGui:GetChildren() do
		local isSameGui = screenGui == gui
		local isAlwaysEnabled = table.find(ALWAYS_ENABLED_GUIS, screenGui.Name)
		local isOurGui = Local.IsOurGui(screenGui)
		-- print(screenGui.Name, isSameGui, isAlwaysEnabled, isOurGui)
		if isSameGui or isAlwaysEnabled or not isOurGui then
			continue
		end

		if screenGui:IsA("ScreenGui") then
			screenGui.Enabled = false
		end
	end
end

function Local.AnimateFrame(frame: Frame, isOpening: boolean)
	local uiScale = Instance.new("UIScale", frame)
	uiScale.Scale = if isOpening then 0.02 else 1

	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
	local tweenGoal = {}
	tweenGoal.Scale = if isOpening then 1 else 0.02

	local tween = TweenService:Create(uiScale, tweenInfo, tweenGoal)
	tween:Play()

	tween.Completed:Connect(function()
		uiScale:Destroy()
		if not isOpening then
			local gui = frame:FindFirstAncestorOfClass("ScreenGui")
			if gui then
				gui.Enabled = false
			end
		end
	end)
end

function Local.IsOurGui(gui: ScreenGui)
	-- Check if this gui exists in our Shared.Guis table
	for _, knownGui in Shared.Guis do
		if gui == knownGui then
			return true
		end
	end
	return false
end

return Shared
