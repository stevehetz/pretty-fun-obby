local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TrailController = require(script.Parent.TrailController)

local TrailsConfig = require(ReplicatedStorage.Configs.Trails)

local Player = Players.LocalPlayer

local Local = {}
local Shared = {}

-- Store active timers
if not Local.ActiveTimers then
	Local.ActiveTimers = {}
end

-- Store active movement connections
if not Local.ActiveMovementConnections then
	Local.ActiveMovementConnections = {}
end

function Shared.OnStart()
	Local.SetupTrailDisplays()
end

function Local.SetupTrailDisplays()
	task.wait(1)

	local _setupTrailDisplays = function()
		local ItemDisplaysFolder = Workspace:WaitForChild("ItemDisplays")
		if not ItemDisplaysFolder then
			warn("ItemDisplays folder not found in Workspace")
			return
		end

		for _, itemDisplay in ipairs(ItemDisplaysFolder:GetChildren()) do
			if itemDisplay:IsA("Model") then
				-- Remove trail from string
				local trailName = itemDisplay.Name:gsub(" Trail", "")
				local trailColorSeq = TrailsConfig.GetTrailColor(trailName)

				if trailColorSeq then
					Local.SetupTrailDisplayPart(itemDisplay, trailColorSeq)
				end
			end
		end
	end

	_setupTrailDisplays()

	-- Recreate trail displays every 30 seconds
	-- This fixes an issue where the trail parts dissapear after a while
	task.spawn(function()
		while true do
			task.wait(30)
			_setupTrailDisplays()
		end
	end)
end

Local.SetupTrailDisplayPart = function(itemDisplay, trailColorSeq)
	-- Remove part named TrailDisplay if it exists
	if itemDisplay:FindFirstChild("TrailDisplay") then
		itemDisplay.TrailDisplay:Destroy()
	end

	-- Create a new trail part
	local itemDisplayDisc = itemDisplay:FindFirstChild("Disc")
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

	-- Calculate the right vector based on the itemDisplay's orientation
	local rightVector = itemDisplay.NamePlate.CFrame.RightVector * 5
	local basePosition = trailPart.Position

	local data = {
		displayId = displayId,
		itemDisplay = itemDisplay,
		trailPart = trailPart,
		trailColorSeq = trailColorSeq,
		rightVector = rightVector,
		basePosition = basePosition,
	}

	-- Function to create a new trail part
	local function createNewTrailPart(data)
		-- Check if the item display still exists
		if not data.itemDisplay:IsDescendantOf(game) then
			-- Clean up if the item display is gone
			if Local.ActiveTimers[data.displayId] then
				task.cancel(Local.ActiveTimers[data.displayId])
				Local.ActiveTimers[data.displayId] = nil
			end
			return
		end

		-- Add trail to the part
		TrailController.AddTrail(data.trailPart, data.trailColorSeq)

		-- Set up movement
		local startTime = os.clock()
		local speed = 1 -- Complete cycles per second
		local amplitude = 8 -- Distance to move in each direction

		-- Clean up any existing connection
		if Local.ActiveMovementConnections[displayId] then
			Local.ActiveMovementConnections[displayId]:Disconnect()
		end

		-- Create a new connection to move the part
		Local.ActiveMovementConnections[data.displayId] = RunService.Heartbeat:Connect(function()
			if not data.trailPart or not data.trailPart:IsDescendantOf(game) then
				if Local.ActiveMovementConnections[data.displayId] then
					Local.ActiveMovementConnections[data.displayId]:Disconnect()
					Local.ActiveMovementConnections[data.displayId] = nil
				end
				return
			end

			-- Calculate the new position using a sine wave
			local elapsed = os.clock() - startTime
			local offset = math.sin(elapsed * math.pi * speed) * amplitude

			-- Move the part along the right vector based on the sine wave
			pcall(function()
				data.trailPart.Position = data.basePosition + data.rightVector.Unit * offset
			end)
		end)
	end

	-- Create the initial trail part
	createNewTrailPart(data)

	-- Set up a timer to recreate the part every 20 seconds
	Local.ActiveTimers[displayId] = task.spawn(function()
		while true do
			task.wait(20) -- Wait 20 seconds
			createNewTrailPart(data) -- Recreate the part
		end
	end)
end

return Shared
