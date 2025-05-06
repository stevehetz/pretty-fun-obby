local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local SkipsGui = require(script.Parent.Guis.Skips)
local GuiController = require(script.Parent.GuiController)
local StateController = require(script.Parent.StateController)
local LeaderboardController = require(script.Parent.LeaderboardController)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)

local Label = GuiController.Guis.TopTwo.Frame.TimerLabel

local GameModeFolder = Workspace:WaitForChild("GameMode")
local CasualDoorModel = GameModeFolder:WaitForChild("CasualDoor")
local CasualDoorInside = CasualDoorModel:WaitForChild("Inside")
local TimedDoorModel = GameModeFolder:WaitForChild("TimedDoor")
local TimedDoorInside = TimedDoorModel:WaitForChild("Inside")
local FinishDoorModel = GameModeFolder:WaitForChild("FinishDoor")
local FinishDoorInside = FinishDoorModel:WaitForChild("Inside")

local finished = false
local timerRunning = false
local startTime = 0
local elapsedTime = 0
local casualDoorDebounce = false
local timedDoorDebounce = false
local finishDoorDebounce = false
local message = nil
local originalColor = Label.TextColor3
local originalSize = Label.TextSize

local Local = {}
local Shared = {}

Shared.GameMode = "Casual"

function Shared.OnStart()
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		-- Get Player State
		if action.type == "UpdateStage" then
			local playerState = StateController.GetState()
			if playerState and playerState.stage == 0 then
				Local.Reset()
			end
		end
	end)

	RunService.Heartbeat:Connect(function()
		if timerRunning then
			elapsedTime = tick() - startTime
			Label.Text = message or Local.FormatTime(elapsedTime)
		end
	end)

	TimedDoorInside.Touched:Connect(function(hit)
		local char = hit.Parent
		if char and char:FindFirstChild("Humanoid") and char == Player.Character and not timerRunning then
			if timedDoorDebounce then
				return
			end
			timedDoorDebounce = true
			task.delay(2, function()
				timedDoorDebounce = false
			end)

			local playerState = StateController.GetState()
			if playerState and playerState.stage > 0 then
				Local.Reset()
				Remotes.Rebirth:FireServer()
				return
			end

			Shared.GameMode = "Timed"
			SkipsGui.HideSkipButton()
			Label.TextColor3 = originalColor
			Label.TextSize = originalSize
			Label.Visible = true
			timerRunning = true
			startTime = tick()
			Label.Text = Local.FormatTime(0)
		end
	end)

	CasualDoorInside.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char or not char:FindFirstChild("Humanoid") or char ~= Player.Character then
			return
		end

		if casualDoorDebounce then
			return
		end
		casualDoorDebounce = true
		task.delay(2, function()
			casualDoorDebounce = false
		end)

		if Shared.GameMode == "Casual" then
			return
		end
		if Shared.GameMode == "Timed" then
			Local.Reset()
			return
		end
	end)

	FinishDoorInside.Touched:Connect(function(hit)
		local char = hit.Parent
		if char and char:FindFirstChild("Humanoid") and char == Player.Character then
			if finished == true then
				return
			end
			if finishDoorDebounce then
				return
			end
			finishDoorDebounce = true
			-- Reset debounce after 2 seconds
			task.delay(2, function()
				finishDoorDebounce = false
			end)

			local currentStage = StateController.GetState().stage

			if currentStage < StagesConfig.GetTotalStages() then
				message = "Must finish all stages!"
				Label.Visible = true
				Label.TextColor3 = Color3.fromRGB(255, 0, 0)
				Label.TextSize = 40

				task.delay(4, function()
					if Shared.GameMode == "Casual" then
						Label.Visible = false
					end
					message = nil
					Label.TextColor3 = originalColor
					Label.TextSize = originalSize
				end)
				return
			end
			finished = true
			if Shared.GameMode == "Timed" then
				-- add 7 minutes to the elapsed time for testing purposes
				-- elapsedTime = elapsedTime + 420
				Remotes.TimedFinish:FireServer(elapsedTime)
				SkipsGui.ShowSkipButton()
				Label.TextColor3 = Color3.fromRGB(0, 255, 0)
				Label.TextSize = 60
				timerRunning = false
			end
			Remotes.WorldFinish:FireServer()
			task.wait(2)
			LeaderboardController.RefreshFinishesLeaderboard()
			LeaderboardController.RefreshTimesLeaderboard()
		end
	end)
end

Local.Reset = function()
	Label.TextColor3 = originalColor
	Label.TextSize = originalSize
	SkipsGui.ShowSkipButton()
	Shared.GameMode = "Casual"
	finished = false
	timerRunning = false
	startTime = 0
	elapsedTime = 0
	finishDoorDebounce = false
	message = nil
	Label.Visible = false
end

function Local.FormatTime(t)
	local minutes = math.floor(t / 60)
	local seconds = t % 60
	-- local seconds = math.floor(t % 60)
	return string.format("%02d:%05.2f", minutes, seconds)
	-- return string.format("%02d:%02d", minutes, seconds)
end

return Shared
