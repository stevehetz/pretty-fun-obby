local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)

local Local = {}
local Shared = {}

PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
	-- print("ToolsService - PlayerDataService.ProfileLoaded.Event")
	Shared.GiveTool(player, "Gravity Coil", 1157798560)
	Shared.GiveTool(player, "Speed Coil", 1157906298)
	Shared.GiveTrashcan(player, "Trashcan")

	player.CharacterAdded:Connect(function(character)
		Shared.GiveTool(player, "Gravity Coil", 1157798560)
		Shared.GiveTool(player, "Speed Coil", 1157906298)
		Shared.GiveTrashcan(player, "Trashcan")
	end)
end)

function Shared.GiveTool(player: Player, toolName: string, gamepassId: number)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local playerOwnsGamepass = state.gamepasses[tostring(gamepassId)] or false
	local ownsTool = playerOwnsGamepass
	if not ownsTool then
		return
	end

	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		return
	end

	local clone = ReplicatedStorage.Tools[toolName]:Clone()
	clone.Parent = backpack
end

function Shared.GiveTrashcan(player: Player)
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not backpack then
		return
	end

	local db = 0
	local tool = ReplicatedStorage.Tools.Trashcan:Clone()
	tool.Parent = backpack

	tool.Activated:Connect(function()
		local player = game.Players:GetPlayerFromCharacter(tool.Parent)
		local trashcanParts = tool.TrashcanParts

		print("Trashcan activated by", player.Name)

		if db == 0 then
			db = 1

			local char = player.Character
			local humanoid = char:FindFirstChild("HumanoidRootPart")

			task.wait(0.3)

			for _, p in pairs(trashcanParts:GetChildren()) do
				p.Transparency = 1
			end

			local clone = ReplicatedStorage.Throwables.TrashCan:Clone()
			clone.Parent = game.Workspace
			clone.Material = Enum.Material.Metal

			-- clone.CustomPhysicalProperties = PhysicalProperties.new(
			-- 	50, -- density
			-- 	0.3, -- friction
			-- 	0.5 -- elasticity
			-- )

			-- Calculate a point 4 studs in front of the HRP, and 4 studs above
			local forwardDistance = 5
			local heightOffset = 3
			local spawnPosition = humanoid.Position
				+ humanoid.CFrame.LookVector * forwardDistance
				+ Vector3.new(0, heightOffset, 0)

			-- Place the part at spawnPosition
			clone.CFrame = CFrame.new(spawnPosition)
			-- Rotate so that its front faces the same direction as the player,
			-- plus the 270° X-rotation you had originally
			clone.Orientation = humanoid.Orientation + Vector3.new(270, 0, 0)

			clone.AssemblyLinearVelocity = humanoid.CFrame.LookVector * 150 + Vector3.new(0, 0.8, 0)

			-- Fade out and remove the thrown trashcan after 3 seconds
			task.delay(2, function()
				-- Create a tween to fade out the trashcan
				local tweenService = game:GetService("TweenService")
				local tweenInfo = TweenInfo.new(
					1, -- Duration (1 second fade)
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				)

				local transparencyGoal = { Transparency = 1 }
				local tween = tweenService:Create(clone, tweenInfo, transparencyGoal)
				tween:Play()

				-- Remove the trashcan after the tween completes
				tween.Completed:Connect(function()
					clone:Destroy()
				end)
			end)

			task.wait(1)

			for _, p in pairs(trashcanParts:GetChildren()) do
				p.Transparency = 0
			end

			db = 0
		end
	end)
end

return Shared
