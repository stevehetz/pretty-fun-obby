local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerPets = Workspace:WaitForChild("PlayerPets")
local PetsFolder = ReplicatedStorage:WaitForChild("Pets")

Players.PlayerAdded:Connect(function(player)
	local folder = Instance.new("Folder")
	folder.Name = player.Name
	folder.Parent = PlayerPets

	-- local pet = PetsFolder:WaitForChild("HallowsSpider"):Clone()
	local pet = PetsFolder:WaitForChild("LilDemon"):Clone()
	pet.Parent = folder
end)

Players.PlayerRemoving:Connect(function(player)
	local folder = PlayerPets:FindFirstChild(player.Name)
	if folder then
		folder:Destroy()
	end
end)
