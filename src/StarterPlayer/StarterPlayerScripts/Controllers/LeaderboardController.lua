local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetCoinRankRF = ReplicatedStorage:WaitForChild("GetCoinRankRF")
local leaderboardsFolder = Workspace:FindFirstChild("Leaderboards")

local REFRESH_INTERVAL = 60 -- Refresh leaderboard every 60 seconds

local Local = {}
local Shared = {}

-- Store the current leaderboard data
Shared.CoinRankLeaderboardData = {}
Shared.LastRefreshTime = 0

Shared.OnStart = function()
	-- if not leaderboardsFolder then
	-- 	return
	-- end

	Shared.RefreshCoinRankLeaderboard()
end

function Shared.RefreshCoinRankLeaderboard()
	if not leaderboardsFolder then
		return
	end

	local success, data = pcall(function()
		return GetCoinRankRF:InvokeServer()
	end)

	if success and data then
		Shared.LastRefreshTime = os.time()
		Shared.CoinRankLeaderboardData = data
		Local.UpdateAllCoinRankLeaderboardUI(data)
		return data
	else
		warn("Failed to refresh leaderboard data")
		return Shared.LeaderboardData
	end
end

function Local.UpdateAllCoinRankLeaderboardUI(data)
	-- Get All Descendents named CoinRankLeaderboard
	local coinrankLeaderboards = leaderboardsFolder:GetDescendants()
	for _, leaderboard in ipairs(coinrankLeaderboards) do
		if leaderboard:IsA("Model") and leaderboard.Name == "CoinRankLeaderboard" then
			-- Update the UI for each leaderboard
			Local.UpdateCoinRankLeaderboardUI(leaderboard, data)
		end
	end
end

function Local.UpdateCoinRankLeaderboardUI(leaderboard, data)
	-- Use pcall with WaitForChild to handle cases where children might not exist
	local success, result = pcall(function()
		local display = leaderboard:WaitForChild("Display", 5)
		local surfaceGui = display:WaitForChild("SurfaceGui", 5)
		local rowsFrame = surfaceGui:WaitForChild("Rows", 5)
		local rowTemplate = rowsFrame:WaitForChild("RowTemplate", 5)

		return {
			rowsFrame = rowsFrame,
			rowTemplate = rowTemplate,
		}
	end)

	if not success then
		warn("Failed to update coinrank leaderboard UI: " .. tostring(result))
		return
	end

	local rowsFrame = result.rowsFrame
	local rowTemplate = result.rowTemplate

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

		-- Set the coins label
		local lblCoins = row:FindFirstChild("Coins")
		if lblCoins then
			lblCoins.Text = entry.coins
		end

		-- Parent after fully configuring
		row.Parent = rowsFrame
	end
end

return Shared
