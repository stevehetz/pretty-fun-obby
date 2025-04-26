local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local GuiController = require(script.Parent.Parent.GuiController)

local Label = GuiController.Guis.TopTwo.Frame.TimerLabel

local TimerFolder = Workspace:WaitForChild("Timer")
local startPad = TimerFolder:WaitForChild("StartPad")
local finishPad = TimerFolder:WaitForChild("FinishPad")

local running = false
local startTime

local Local = {}
local Shared = {}

function Shared.OnStart()
	RunService.Heartbeat:Connect(function()
		if running then
			local elapsed = tick() - startTime
			Label.Text = Local.FormatTime(elapsed)
		end
	end)

	startPad.Touched:Connect(function(hit)
		local char = hit.Parent
		if char and char:FindFirstChild("Humanoid") and not running then
			Label.Visible = true
			running = true
			startTime = tick()
			Label.Text = Local.FormatTime(0)
		end
	end)

	finishPad.Touched:Connect(function(hit)
		local char = hit.Parent
		if char and char:FindFirstChild("Humanoid") and running then
			running = false
			local finalTime = tick() - startTime
			Local.Text = Local.FormatTime(finalTime)
			-- you can fire a RemoteEvent to the server here to record the time
		end
	end)
end

function Local.FormatTime(t)
	local minutes = math.floor(t / 60)
	local seconds = math.floor(t % 60)
	-- return string.format("%02d:%05.2f", minutes, seconds)
	return string.format("%02d:%02d", minutes, seconds)
end

return Shared
