local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local Local = {}
local Shared = {}

Local.Trails = {
	["Green"] = {
		ColorSequence = ColorSequence.new(Color3.new(0.4, 0.894117, 0.364705), Color3.new(1, 1, 1)),
		Width = 1,
		Lifetime = 0.4,
	},
	["Red"] = {
		ColorSequence = ColorSequence.new(Color3.new(1, 0, 0), Color3.new(1, 1, 1)),
		Width = 1,
		Lifetime = 0.4,
	},
	["Blue"] = {
		ColorSequence = ColorSequence.new(Color3.new(0, 0, 1), Color3.new(1, 1, 1)),
		Width = 1,
		Lifetime = 0.4,
	},
	["Rainbow"] = {
		ColorSequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)), -- Red
			ColorSequenceKeypoint.new(0.2, Color3.new(1, 0.5, 0)), -- Orange
			ColorSequenceKeypoint.new(0.4, Color3.new(1, 1, 0)), -- Yellow
			ColorSequenceKeypoint.new(0.6, Color3.new(0, 1, 0)), -- Green
			ColorSequenceKeypoint.new(0.8, Color3.new(0, 0, 1)), -- Blue
			ColorSequenceKeypoint.new(1, Color3.new(0.5, 0, 1)), -- Purple
		}),
		Width = 1,
		Lifetime = 0.4,
	},
	["RedBlueOrange"] = {
		ColorSequence = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)), -- Red
			ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 1)), -- Blue
			ColorSequenceKeypoint.new(1, Color3.new(1, 0.5, 0)), -- Orange
		}),
		Width = 1,
		Lifetime = 0.4,
	},
}

function Shared.OnStart()
	local character = Player.Character or Player.CharacterAdded:Wait()
	if character then
		local part = character:WaitForChild("HumanoidRootPart")
		-- Local.AddTrail(part, Local.Trails["RedBlueOrange"])
	end

	Player.CharacterAdded:Connect(function(character)
		local part = character:WaitForChild("HumanoidRootPart")
	end)

	-- Setup item displays
	Local.SetupItemDisplays()

	-- Set up a periodic check to ensure all trail displays are still working
	task.spawn(function()
		while true do
			task.wait(30) -- Check every 30 seconds
			Local.SetupItemDisplays() -- This will recreate any missing displays
		end
	end)
end

Local.SetupItemDisplays = function()
	task.wait(1) -- Wait for item displays to load
	local ItemDisplaysFolder = Workspace:WaitForChild("ItemDisplays")
	if not ItemDisplaysFolder then
		warn("ItemDisplays folder not found in Workspace")
		return
	end

	-- Iterate through all ItemDisplays
	for _, itemDisplay in ipairs(ItemDisplaysFolder:GetChildren()) do
		if itemDisplay:IsA("Model") then
			if itemDisplay.Name == "Green Trail" then
				-- Use the green trail for Green Trail
				Local.SetupTrailDisplayPart(itemDisplay, Local.Trails["Green"])
			elseif itemDisplay.Name == "Red Trail" then
				-- Use the red trail for Red Trail
				Local.SetupTrailDisplayPart(itemDisplay, Local.Trails["Red"])
			elseif itemDisplay.Name == "Blue Trail" then
				-- Use the blue trail for Blue Trail
				Local.SetupTrailDisplayPart(itemDisplay, Local.Trails["Blue"])
			elseif itemDisplay.Name == "Rainbow Trail" then
				-- Use the rainbow trail for Rainbow Trail
				Local.SetupTrailDisplayPart(itemDisplay, Local.Trails["Rainbow"])
			elseif itemDisplay.Name == "RedBlueOrange Trail" then
				-- Use the red blue orange trail for RedBlueOrange Trail
				Local.SetupTrailDisplayPart(itemDisplay, Local.Trails["RedBlueOrange"])
			end
		end
	end
end

-- Store original parts and their data
if not Local.OriginalParts then
	Local.OriginalParts = {}
end

-- Store active timers
if not Local.ActiveTimers then
	Local.ActiveTimers = {}
end

-- Store active movement connections
if not Local.ActiveMovementConnections then
	Local.ActiveMovementConnections = {}
end

Local.SetupTrailDisplayPart = function(itemDisplay, trailConfig)
	local itemDisplayDisc = itemDisplay:FindFirstChild("Disc")
	-- create new 2x2 part
	local trailPart = Instance.new("Part")
	trailPart.Name = "TrailDisplay"
	trailPart.Size = Vector3.new(2, 2, 2)
	trailPart.Transparency = 1
	trailPart.CanCollide = false
	trailPart.Parent = itemDisplay
	trailPart.Position = itemDisplayDisc.Position + Vector3.new(0, 5, 0)

	-- Generate a unique ID for this display
	local displayId = itemDisplay:GetFullName()

	-- Clean up any existing timer for this display
	if Local.ActiveTimers[displayId] then
		task.cancel(Local.ActiveTimers[displayId])
		Local.ActiveTimers[displayId] = nil
	end

	-- Clean up any existing connection for this display
	if Local.ActiveMovementConnections[displayId] then
		Local.ActiveMovementConnections[displayId]:Disconnect()
		Local.ActiveMovementConnections[displayId] = nil
	end

	-- Store original part properties if not already stored
	if not Local.OriginalParts[displayId] then
		-- Clone the part to save its properties
		local originalPart = trailPart:Clone()
		originalPart.Name = "OriginalTrailPart"
		originalPart.Parent = nil -- Don't add to workspace

		-- Calculate the right vector based on the itemDisplay's orientation
		local rightVector = itemDisplay.NamePlate.CFrame.RightVector * 5

		-- Store original data
		Local.OriginalParts[displayId] = {
			part = originalPart,
			trailConfig = trailConfig,
			itemDisplay = itemDisplay,
			rightVector = rightVector,
			basePosition = trailPart.Position,
		}
	end

	-- Function to create a new trail part
	local function createNewTrailPart()
		-- Get the stored data
		local data = Local.OriginalParts[displayId]
		if not data then
			return
		end

		-- Check if the item display still exists
		if not data.itemDisplay:IsDescendantOf(game) then
			-- Clean up if the item display is gone
			Local.OriginalParts[displayId] = nil
			if Local.ActiveTimers[displayId] then
				task.cancel(Local.ActiveTimers[displayId])
				Local.ActiveTimers[displayId] = nil
			end
			return
		end

		-- Remove existing part if it exists
		local existingPart = data.itemDisplay:FindFirstChild("TrailDisplay")
		if existingPart then
			existingPart:Destroy()
		end

		-- Create a new part from the original
		local newPart = data.part:Clone()
		newPart.Name = "TrailDisplay"
		newPart.Parent = data.itemDisplay
		newPart.Position = data.basePosition
		newPart.Transparency = 1
		newPart.CanCollide = false

		-- Add trail to the part
		Local.AddTrail(newPart, data.trailConfig)

		-- Set up movement
		local startTime = os.clock()
		local speed = 1 -- Complete cycles per second
		local amplitude = 8 -- Distance to move in each direction

		-- Clean up any existing connection
		if Local.ActiveMovementConnections[displayId] then
			Local.ActiveMovementConnections[displayId]:Disconnect()
		end

		-- Create a new connection to move the part
		Local.ActiveMovementConnections[displayId] = RunService.Heartbeat:Connect(function()
			if not newPart or not newPart:IsDescendantOf(game) then
				if Local.ActiveMovementConnections[displayId] then
					Local.ActiveMovementConnections[displayId]:Disconnect()
					Local.ActiveMovementConnections[displayId] = nil
				end
				return
			end

			-- Calculate the new position using a sine wave
			local elapsed = os.clock() - startTime
			local offset = math.sin(elapsed * math.pi * speed) * amplitude

			-- Move the part along the right vector based on the sine wave
			pcall(function()
				newPart.Position = data.basePosition + data.rightVector.Unit * offset
			end)
		end)
	end

	-- Create the initial trail part
	createNewTrailPart()

	-- Set up a timer to recreate the part every 20 seconds
	Local.ActiveTimers[displayId] = task.spawn(function()
		while true do
			task.wait(20) -- Wait 20 seconds
			createNewTrailPart() -- Recreate the part
		end
	end)
end

function Local.AddTrail(part, trailConfig)
	local att0 = Instance.new("Attachment", part)
	att0.Position = Vector3.new(0, 2, 0)

	local att1 = Instance.new("Attachment", part)
	att1.Position = Vector3.new(0, -2, 0)

	local trail = Instance.new("Trail", part)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = trailConfig.Lifetime
	trail.WidthScale = NumberSequence.new(trailConfig.Width)
	trail.Color = trailConfig.ColorSequence
end

return Shared
