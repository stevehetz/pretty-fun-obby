local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetTopFinishersRF = ReplicatedStorage:WaitForChild("GetTopFinishers")
local StagesFolder = Workspace:WaitForChild("Stages")
local StageZero = StagesFolder:WaitForChild("0")
local leaderboardModel = StageZero:WaitForChild("FinishesLeaderboard")
local displayPart = leaderboardModel:WaitForChild("Display")
local surfaceGui = displayPart:WaitForChild("SurfaceGui")
local rowsFrame = surfaceGui:WaitForChild("Rows")
local listLayout = rowsFrame:WaitForChild("UIListLayout")
local rowTemplate = rowsFrame:WaitForChild("RowTemplate")

-- Adjust canvas size to be larger to accommodate all rows
surfaceGui.CanvasSize = Vector2.new(500, 600) -- Increased height to 600
surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- Ensure consistent sizing

local REFRESH_INTERVAL = 60 -- Refresh leaderboard every 60 seconds

local Local = {}
local Shared = {}

-- Store the current leaderboard data
Shared.LeaderboardData = {}
Shared.LastRefreshTime = 0

Shared.OnStart = function()
	-- Initial fetch
	Shared.RefreshLeaderboard()

	-- Set up periodic refresh
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			Shared.RefreshLeaderboard()
		end
	end)
end

-- Function to refresh leaderboard data
function Shared.RefreshLeaderboard()
	local success, data = pcall(function()
		return GetTopFinishersRF:InvokeServer()
	end)

	if success and data then
		Shared.LeaderboardData = data
		Shared.LastRefreshTime = os.time()
		Local.UpdateLeaderboardUI(data)
		return data
	else
		warn("Failed to refresh leaderboard data")
		return Shared.LeaderboardData -- Return existing data on failure
	end
end

function Local.UpdateLeaderboardUI(data)
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

return Shared
