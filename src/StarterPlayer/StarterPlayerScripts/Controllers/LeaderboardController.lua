local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetTopFinishersRF = ReplicatedStorage:WaitForChild("GetTopFinishers")
local GetTopTimesRF = ReplicatedStorage:WaitForChild("GetTopTimes")
local GetTimeUntilRefreshRF = ReplicatedStorage:WaitForChild("GetTimeUntilRefresh")
local GetTopTwoTimesPerWorldRF = ReplicatedStorage:WaitForChild("GetTopTwoTimesPerWorldRF")
local leaderboardsFolder = Workspace:WaitForChild("Leaderboards")
local worldPortalsFolder = Workspace:WaitForChild("WorldPortals")

local REFRESH_INTERVAL = 60 -- Refresh leaderboard every 60 seconds

local Local = {}
local Shared = {}

-- Store the current leaderboard data
Shared.FinishesLeaderboardData = {}
Shared.TimesLeaderboardData = {}
Shared.TopTwoTimesPerWorldData = {}
Shared.LastRefreshTime = 0

Shared.OnStart = function()
	-- Initial fetch - do sequentially to ensure each completes before moving to the next
	local finishesData = Shared.RefreshFinishesLeaderboard()
	task.wait(0.5) -- Small delay between refreshes

	-- local timesData = Shared.RefreshTimesLeaderboard()
	-- task.wait(0.5) -- Small delay between refreshes

	-- local topTwoData = Shared.RefreshTopTwoTimesPerWorld()
	-- Shared.UpdateTimeUntilRefresh()

	-- Set up periodic refresh for leaderboards
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)

			-- Refresh leaderboards sequentially to ensure each completes before moving to the next
			local finishesData = Shared.RefreshFinishesLeaderboard()
			task.wait(0.5) -- Small delay between refreshes

			local timesData = Shared.RefreshTimesLeaderboard()
			task.wait(0.5) -- Small delay between refreshes

			local topTwoData = Shared.RefreshTopTwoTimesPerWorld()
		end
	end)

	-- Set up periodic refresh for time until refresh (every minute)
	task.spawn(function()
		Shared.UpdateTimeUntilRefresh()
		while true do
			task.wait(10) -- Update every minute
			Shared.UpdateTimeUntilRefresh()
		end
	end)
end

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
	-- Use pcall with WaitForChild to handle cases where children might not exist
	local success, result = pcall(function()
		local display = leaderboard:WaitForChild("Display", 5)
		local surfaceGui = display:WaitForChild("SurfaceGui", 5)
		local rowsFrame = surfaceGui:WaitForChild("Rows", 5)
		local rowTemplate = rowsFrame:WaitForChild("RowTemplate", 5)

		return {
			display = display,
			surfaceGui = surfaceGui,
			rowsFrame = rowsFrame,
			rowTemplate = rowTemplate,
		}
	end)

	if not success then
		warn("Failed to update finishes leaderboard UI: " .. tostring(result))
		return
	end

	local display = result.display
	local surfaceGui = result.surfaceGui
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
	-- Use pcall with WaitForChild to handle cases where children might not exist
	local success, result = pcall(function()
		local display = leaderboard:WaitForChild("Display", 5)
		local surfaceGui = display:WaitForChild("SurfaceGui", 5)
		local rowsFrame = surfaceGui:WaitForChild("Rows", 5)
		local rowTemplate = rowsFrame:WaitForChild("RowTemplate", 5)

		return {
			display = display,
			surfaceGui = surfaceGui,
			rowsFrame = rowsFrame,
			rowTemplate = rowTemplate,
		}
	end)

	if not success then
		warn("Failed to update times leaderboard UI: " .. tostring(result))
		return
	end

	local display = result.display
	local surfaceGui = result.surfaceGui
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

-- Function to update the time until refresh display
function Shared.UpdateTimeUntilRefresh()
	local success, timeUntilRefresh = pcall(function()
		return GetTimeUntilRefreshRF:InvokeServer()
	end)

	if not success or not timeUntilRefresh then
		warn("Failed to get time until refresh")
		return
	end

	-- Format the time into days, hours, minutes
	local days = math.floor(timeUntilRefresh / (24 * 60 * 60))
	local hours = math.floor((timeUntilRefresh % (24 * 60 * 60)) / 3600)
	local minutes = math.floor((timeUntilRefresh % 3600) / 60)

	local formattedTime = string.format("%d days %d hr %d min", days, hours, minutes)

	-- Find all refresh time labels in the leaderboards folder
	local signs = leaderboardsFolder:GetDescendants()
	for _, sign in ipairs(signs) do
		if sign.Name == "Sign" and sign:IsA("Model") then
			local display = sign:WaitForChild("Display", 5)
			local surfaceGui = display:WaitForChild("SurfaceGui", 5)
			local frame = surfaceGui:WaitForChild("Frame", 5)
			local label = frame:WaitForChild("TimeRemaining", 5)
			label.Text = formattedTime
		end
	end
end

function Shared.RefreshTopTwoTimesPerWorld()
	local success, data = pcall(function()
		return GetTopTwoTimesPerWorldRF:InvokeServer()
	end)

	if success and data then
		Shared.LastRefreshTime = os.time()
		Shared.TopTwoTimesPerWorldData = data
		Local.UpdateAllLeaderScreens(data)
		return data
	else
		warn("Failed to refresh top two times per world data")
		return Shared.TopTwoTimesPerWorldData
	end
end

function Local.UpdateAllLeaderScreens(data)
	-- Find all LeaderScreen objects in the WorldPortals folder
	for _, worldModel in ipairs(worldPortalsFolder:GetChildren()) do
		if worldModel:IsA("Model") then
			local worldName = worldModel.Name

			-- Find LeaderScreen in this world folder
			for _, leaderScreen in ipairs(worldModel:GetDescendants()) do
				if leaderScreen.Name == "LeaderScreen" and leaderScreen:IsA("Model") then
					-- Update this LeaderScreen with data for its world
					Local.UpdateLeaderScreen(leaderScreen, worldName, data[worldName] or {})
				end
			end
		end
	end
end

function Local.UpdateLeaderScreen(leaderScreen, worldName, worldData)
	-- Use pcall with WaitForChild to handle cases where children might not exist
	local success, result = pcall(function()
		local display = leaderScreen:WaitForChild("display", 5)
		local surfaceGui = display:WaitForChild("SurfaceGui", 5)
		local frame = surfaceGui:WaitForChild("Frame", 5)
		local rowTemplate = frame:WaitForChild("RowTemplate", 5)

		return {
			display = display,
			surfaceGui = surfaceGui,
			frame = frame,
			rowTemplate = rowTemplate,
		}
	end)

	if not success then
		warn("Failed to update LeaderScreen UI for " .. worldName .. ": " .. tostring(result))
		return
	end

	local frame = result.frame
	local rowTemplate = result.rowTemplate

	-- Clear existing rows
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "RowTemplate" and not child:FindFirstChild("UIListLayout") then
			child:Destroy()
		end
	end

	-- Make sure template is properly configured and hidden
	rowTemplate.Visible = false

	-- If we have no data for this world, show a message
	if #worldData == 0 then
		local noDataLabel = Instance.new("TextLabel")
		noDataLabel.Name = "NoDataLabel"
		noDataLabel.Size = UDim2.new(1, 0, 0, 80)
		noDataLabel.BackgroundTransparency = 1
		noDataLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		noDataLabel.Text = "No times recorded yet"
		noDataLabel.TextSize = 60
		noDataLabel.Font = Enum.Font.GothamBold
		noDataLabel.Parent = frame
		return
	end

	-- Populate with top 2 players
	for _, entry in ipairs(worldData) do
		-- Create a deep copy of the template
		local row = rowTemplate:Clone()
		row.Name = "Row" .. entry.rank
		row.Visible = true

		-- Set the rank label
		local lblRank = row:FindFirstChild("Rank")
		if lblRank then
			lblRank.Text = "#" .. entry.rank
		end

		-- Set avatar image
		local avatar = row:FindFirstChild("Avatar")
		if avatar then
			avatar.Image = entry.avatarUrl
		end

		-- Set the player name label
		local playerLabel = row:FindFirstChild("Player")
		if playerLabel then
			playerLabel.Text = entry.username
		end

		-- Parent after fully configuring
		row.Parent = frame
	end
end

return Shared
