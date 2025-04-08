local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiController = require(script.Parent.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.Parent.StateController)
local Remotes = ReplicatedStorage.Remotes

local Gui = GuiController.Guis.Skips
local Frame = Gui.Frame
local ProgressBar = Frame.ProgressBar
local UseButton = Frame.Use
local ExitButton = Frame.Exit
local OpenButton = GuiController.Guis.Top.Frame.Skip

local USE_BUTTON_TEXT = "Use (REPLACE)"
local SKIP_COOLDOWN = 120

local Local = {}
local Shared = {}

function Shared.OnStart()
	-- OpenButton.MouseButton1Click:Connect(function()
	-- 	Remotes.Skip:FireServer()
	-- end)

	-- local hasSkips = StateController.GetState().skips.amount > 0
	-- OpenButton.Notification.Visible = hasSkips

	-- Local.UpdateUseButton()

	OpenButton.MouseButton1Click:Connect(function()
		print("OpenButton.MouseButton1Click")
		Gui.Enabled = not Gui.Enabled
		GuiController.ToggleBlurEffect(Gui.Enabled)
	end)

	ExitButton.MouseButton1Click:Connect(function()
		Gui.Enabled = false
		GuiController.ToggleBlurEffect(Gui.Enabled)
	end)

	UseButton.MouseButton1Click:Connect(function()
		Remotes.Skip:FireServer()
	end)

	-- Gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	-- 	if Gui.Enabled then
	-- 		Local.UpdateProgressBar()
	-- 		OpenButton.Notification.Visible = false
	-- 	end
	-- end)

	-- StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
	-- 	local isEarnedSkip = action.type == "EarnSkip"
	-- 	local isUseSkip = action.type == "UseSkip"

	-- 	if isEarnedSkip or isUseSkip then
	-- 		Local.UpdateUseButton()
	-- 	end

	-- 	local isGuiEnabled = Gui.Enabled
	-- 	if isEarnedSkip and not isGuiEnabled then
	-- 		OpenButton.Notification.Visible = true
	-- 	end
	-- end)
end

-- function Local.UpdateUseButton()
-- 	local skips = StateController.GetState().skips.amount
-- 	UseButton.Title.Text = USE_BUTTON_TEXT:gsub("REPLACE", skips)
-- end

-- function Local.UpdateProgressBar()
-- 	task.spawn(function()
-- 		while Gui.Enabled do
-- 			pcall(function()
-- 				local nextSkip = StateController.GetState().skips.next
-- 				local currentTime = os.time()
-- 				local secondsLeft = math.max(0, nextSkip - currentTime)
-- 				local progress = (SKIP_COOLDOWN - secondsLeft) / SKIP_COOLDOWN
-- 				local minutes = math.floor(secondsLeft / 60)
-- 				local seconds = secondsLeft % 60
-- 				local timeText = string.format("%02d:%02d", minutes, seconds)
-- 				GuiController.HandleProgressBar(ProgressBar, progress, timeText)
-- 			end)
-- 			task.wait(1)
-- 		end
-- 	end)
-- end

return Shared
