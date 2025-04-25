WorldsConfig = require(game.ReplicatedStorage.Configs.Worlds)

local placeId = game.PlaceId
local worldName = "World2" -- This should be set based on the game context
local worldPlaceId = WorldsConfig.GetPlaceIdFromWorldName(worldName)

if placeId == worldPlaceId then
	-- LocalScript in StarterPlayerScripts
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	function ClonePartAndHandleTouched()
		-- Wait for and clone your template
		local stagesFolder = ReplicatedStorage:WaitForChild("Stages")
		local stage = stagesFolder:WaitForChild("23")
		local template = stage:WaitForChild("FallingPartTemplate")
		local myPart = template:Clone()
		myPart.Parent = workspace
		-- (optional) adjust CFrame if needed; otherwise it stays where the template is

		local playerTouched = false

		-- Only un-anchor when *this* player’s character touches it
		myPart.Touched:Connect(function(hit)
			if playerTouched then
				return
			end

			playerTouched = true
			local char = player.Character
			if char and hit:IsDescendantOf(char) then
				task.wait(1)
				myPart.Anchored = false

				task.wait(3)

				-- destroy and recreate the part
				myPart:Destroy()
				ClonePartAndHandleTouched()
			end
		end)
	end

	ClonePartAndHandleTouched()
end
