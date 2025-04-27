local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetTopFinishersRF = ReplicatedStorage:WaitForChild("GetTopFinishers")
local GetTopTimesRF = ReplicatedStorage:WaitForChild("GetTopTimes")
local leaderboardsFolder = Workspace:WaitForChild("Leaderboards")

local REFRESH_INTERVAL = 60 -- Refresh leaderboard every 60 seconds

local Local = {}
local Shared = {}

-- Store the current leaderboard data
Shared.FinishesLeaderboardData = {}
Shared.TimesLeaderboardData = {}
Shared.LastRefreshTime = 0

Shared.OnStart = function()
	-- Initial fetch
	Shared.RefreshFinishesLeaderboard()
	Shared.RefreshTimesLeaderboard()

	-- Set up periodic refresh
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			Shared.RefreshFinishesLeaderboard()
			Shared.RefreshTimesLeaderboard()
		end
	end)
end

-- Function to refresh leaderboard data
function Shared.RefreshFinishesLeaderboard()
	local success, data = pcall(function()
		return GetTopFinishersRF:InvokeServer()
	end)

	if success and data then
		Shared.LastRefreshTime = os.time()
		Shared.FinishesLeaderboardData = data
		Local.UpdateAllFinshesLeaderboardUI(data)
		return data
	else
		warn("Failed to refresh leaderboard data")
		return Shared.LeaderboardData
	end
end

function Shared.RefreshTimesLeaderboard()
	local success, data = pcall(function()
		return GetTopTimesRF:InvokeServer()
	end)

	if success and data then
		Shared.LastRefreshTime = os.time()
		Shared.TimesLeaderboardData = data
		print("Times Leaderboard Data: ", data)
		Local.UpdateAllTimesLeaderboardUI(data)
		return data
	else
		warn("Failed to refresh times leaderboard data")
		return Shared.TimesLeaderboardData
	end
end

function Local.UpdateAllFinshesLeaderboardUI(data)
	-- Get All Descendents named FinishesLeaderboard
	local finishesLeaderboards = leaderboardsFolder:GetDescendants()
	for _, leaderboard in ipairs(finishesLeaderboards) do
		if leaderboard:IsA("Model") and leaderboard.Name == "FinishesLeaderboard" then
			-- Update the UI for each leaderboard
			Local.UpdateFinishesLeaderboardUI(leaderboard, data)
		end
	end
end

function Local.UpdateFinishesLeaderboardUI(leaderboard, data)
	local display = leaderboard:FindFirstChild("Display")
	local surfaceGui = display:FindFirstChild("SurfaceGui")
	local rowsFrame = surfaceGui:FindFirstChild("Rows")
	local rowTemplate = rowsFrame:FindFirstChild("RowTemplate")

	-- Clear existing rows
	for _, child in ipairs(rowsFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "RowTemplate" and child.Name ~= "Header" then
			child:Destroy()
		end
	end

	-- Make sure template is properly configured and hidden
	rowTemplate.Visible = false

	-- Populate new rows
	for _, entry in ipairs(data) do
		-- Create a deep copy of the template
		local row = rowTemplate:Clone()
		row.Name = "Row" .. entry.rank
		row.Visible = true

		if entry.rank == 1 then
			row.BackgroundTransparency = 0.7
			row.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		elseif entry.rank == 2 then
			row.BackgroundTransparency = 0.7
			row.BackgroundColor3 = Color3.fromRGB(192, 192, 192) -- Silver
		elseif entry.rank == 3 then
			row.BackgroundTransparency = 0.7
			row.BackgroundColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
		end

		-- Set the rank label
		local lblRank = row:FindFirstChild("Rank")
		if lblRank then
			lblRank.Text = entry.rank
		end

		-- Set avatar image
		local avatar = row:FindFirstChild("Avatar")
		if avatar then
			avatar.Image = entry.avatarUrl
			-- avatar.Image = "rbxthumb://type=AvatarBust&id=6164663905&w=48&h=48"
		end

		-- Set the text label
		local lbl = row:FindFirstChild("Player")
		if lbl then
			lbl.Text = entry.username
		end

		-- Set the finishes label
		local lblFinishes = row:FindFirstChild("Finishes")
		if lblFinishes then
			lblFinishes.Text = entry.finishes
		end

		-- Parent after fully configuring
		row.Parent = rowsFrame
	end
end

function Local.UpdateAllTimesLeaderboardUI(data)
	-- Get All Descendents named TimesLeaderboard
	local timesLeaderboards = leaderboardsFolder:GetDescendants()
	for _, leaderboard in ipairs(timesLeaderboards) do
		if leaderboard:IsA("Model") and leaderboard.Name == "TimesLeaderboard" then
			-- Update the UI for each leaderboard
			Local.UpdateTimesLeaderboardUI(leaderboard, data)
		end
	end
end

function Local.UpdateTimesLeaderboardUI(leaderboard, data)
	local display = leaderboard:FindFirstChild("Display")
	if not display then
		return
	end

	local surfaceGui = display:FindFirstChild("SurfaceGui")
	if not surfaceGui then
		return
	end

	local rowsFrame = surfaceGui:FindFirstChild("Rows")
	if not rowsFrame then
		return
	end

	local rowTemplate = rowsFrame:FindFirstChild("RowTemplate")
	if not rowTemplate then
		return
	end

	-- Clear existing rows
	for _, child in ipairs(rowsFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "RowTemplate" and child.Name ~= "Header" then
			child:Destroy()
		end
	end

	-- Make sure template is properly configured and hidden
	rowTemplate.Visible = false

	-- Populate new rows
	for _, entry in ipairs(data) do
		-- Create a deep copy of the template
		local row = rowTemplate:Clone()
		row.Name = "Row" .. entry.rank
		row.Visible = true

		if entry.rank == 1 then
			row.BackgroundTransparency = 0.7
			row.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
		elseif entry.rank == 2 then
			row.BackgroundTransparency = 0.7
			row.BackgroundColor3 = Color3.fromRGB(192, 192, 192) -- Silver
		elseif entry.rank == 3 then
			row.BackgroundTransparency = 0.7
			row.BackgroundColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
		end

		-- Set the rank label
		local lblRank = row:FindFirstChild("Rank")
		if lblRank then
			lblRank.Text = entry.rank
		end

		-- Set avatar image
		local avatar = row:FindFirstChild("Avatar")
		if avatar then
			avatar.Image = entry.avatarUrl
		end

		-- Set the text label
		local lbl = row:FindFirstChild("Player")
		if lbl then
			lbl.Text = entry.username
		end

		-- Set the time label with proper formatting
		local lblTime = row:FindFirstChild("Time")
		if lblTime then
			-- Format time as MM:SS.ss
			local minutes = math.floor(entry.time / 60)
			local seconds = entry.time % 60
			lblTime.Text = string.format("%02d:%05.2f", minutes, seconds)
		end

		-- Parent after fully configuring
		row.Parent = rowsFrame
	end
end

return Shared
