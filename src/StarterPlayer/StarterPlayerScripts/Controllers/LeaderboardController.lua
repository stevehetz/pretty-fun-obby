local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GetTopFinishersRF = ReplicatedStorage:WaitForChild("GetTopFinishers")
local StagesFolder = Workspace:WaitForChild("Stages")
local StageZero = StagesFolder:WaitForChild("0")
local leaderboardModel = StageZero:WaitForChild("Leaderboard")
local displayPart = leaderboardModel:WaitForChild("Display")
local surfaceGui = displayPart:WaitForChild("SurfaceGui")
local rowsFrame = surfaceGui:WaitForChild("Rows")
local listLayout = rowsFrame:WaitForChild("UIListLayout")
local template = rowsFrame:WaitForChild("RowTemplate")

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
	-- Clear old rows (keeping the hidden template)
	for _, child in ipairs(rowsFrame:GetChildren()) do
		if child ~= template and child ~= listLayout then
			child:Destroy()
		end
	end

	-- Make sure template is properly configured and hidden
	template.Visible = false
	template.Size = UDim2.new(1, 0, 0, 40)

	-- Manually position rows instead of relying on UIListLayout
	local yOffset = 0
	local rowHeight = 44 -- 40px height + 4px padding

	-- Create header row
	local header = template:Clone()
	header.Name = "Header"
	header.Position = UDim2.new(0, 0, 0, yOffset)
	header.Size = UDim2.new(1, 0, 0, 40)
	header.AnchorPoint = Vector2.new(0, 0)
	header.ZIndex = 100 -- Ensure header is always on top
	header.Visible = true

	-- Style the header differently if needed
	local headerLabel = header:FindFirstChild("PlayerLabel")
	if headerLabel then
		headerLabel.Text = "Rank - Player - Finishes"
		headerLabel.FontFace = Font.fromName("GothamBold", Enum.FontWeight.Bold)
	end

	-- Clear the avatar for the header
	local headerAvatar = header:FindFirstChild("Avatar")
	if headerAvatar then
		headerAvatar.Image = ""
	end

	header.Parent = rowsFrame

	-- Increment offset for the first data row
	yOffset = yOffset + rowHeight

	-- Populate new rows
	for _, entry in ipairs(data) do
		-- Create a deep copy of the template
		local row = template:Clone()
		row.Name = "Row" .. entry.rank

		-- Set position manually
		row.Position = UDim2.new(0, 0, 0, yOffset)
		row.Size = UDim2.new(1, 0, 0, 40)
		row.AnchorPoint = Vector2.new(0, 0)
		row.ZIndex = entry.rank -- Ensure proper layering
		row.Visible = true

		-- Set avatar image
		local avatar = row:FindFirstChild("Avatar")
		if avatar then
			avatar.Image = entry.avatarUrl
		end

		-- Set the text label
		local lbl = row:FindFirstChild("PlayerLabel")
		if lbl then
			lbl.Text = string.format("%d. %s — %d", entry.rank, entry.username, entry.finishes)
		end

		-- Parent after fully configuring
		row.Parent = rowsFrame

		-- Increment offset for next row
		yOffset = yOffset + rowHeight
	end
end

return Shared
