local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local GuiController = require(script.Parent.GuiController)

local Label = GuiController.Guis.TopTwo.Frame.TimerLabel

local GameModeFolder = Workspace:WaitForChild("GameMode")
local CasualDoorModel = GameModeFolder:WaitForChild("CasualDoor")
local CasualDoorInside = CasualDoorModel:WaitForChild("Inside")
local TimedDoorModel = GameModeFolder:WaitForChild("TimedDoor")
local TimedDoorInside = TimedDoorModel:WaitForChild("Inside")
local FinishDoorModel = GameModeFolder:WaitForChild("FinishDoor")
local FinishDoorInside = FinishDoorModel:WaitForChild("Inside")

local gameMode = "Casual"
local finished = false
local timerRunning = false
local startTime = 0
local elapsedTime = 0

local Local = {}
local Shared = {}

function Shared.OnStart()
	RunService.Heartbeat:Connect(function()
		if timerRunning then
			elapsedTime = tick() - startTime
			Label.Text = Local.FormatTime(elapsedTime)
		end
	end)

	TimedDoorInside.Touched:Connect(function(hit)
		if gameMode == "Timed" then
			return
		end
		local char = hit.Parent
		if char and char:FindFirstChild("Humanoid") and not timerRunning then
			gameMode = "Timed"
			Label.Visible = true
			timerRunning = true
			startTime = tick()
			Label.Text = Local.FormatTime(0)
		end
	end)

	CasualDoorInside.Touched:Connect(function(hit)
		if gameMode == "Casual" then
			return
		end
		local char = hit.Parent
		if char and char:FindFirstChild("Humanoid") and timerRunning then
			gameMode = "Casual"
			timerRunning = false
			Label.Visible = false
		end
	end)

	FinishDoorInside.Touched:Connect(function(hit)
		if gameMode == "Casual" or finished == true then
			return
		end
		local char = hit.Parent
		if char and char:FindFirstChild("Humanoid") and timerRunning then
			finished = true
			timerRunning = false
			Label.TextColor3 = Color3.fromRGB(0, 255, 0)
			Label.TextSize = 60
			Remotes.TimedFinish:FireServer(elapsedTime)
		end
	end)
end

function Local.FormatTime(t)
	local minutes = math.floor(t / 60)
	local seconds = t % 60
	-- local seconds = math.floor(t % 60)
	return string.format("%02d:%05.2f", minutes, seconds)
	-- return string.format("%02d:%02d", minutes, seconds)
end

return Shared
