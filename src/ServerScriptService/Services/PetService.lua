local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local PlayerPets = Workspace:WaitForChild("PlayerPets")
local PetsFolder = ReplicatedStorage:WaitForChild("Pets")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.PlayerData.UpdateEquippedPet.OnServerEvent:Connect(function(player, pet)
		Shared.UpdateEquippedPets(player, pet)
	end)

	PlayerDataService.ProfileLoaded.Event:Connect(function(player)
		Local.RefreshEquippedPets(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local folder = PlayerPets:FindFirstChild(player.Name)
		if folder then
			folder:Destroy()
		end
	end)
end

function Shared.UpdateEquippedPets(player: Player, pet)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local currentValue = state.equippedPets[pet.Name]
	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateEquippedPets",
		petName = pet.Name,
		value = not currentValue,
	}

	PlayerDataService.UpdateState(player, action)
	Local.RefreshEquippedPets(player)
end

function Local.RefreshEquippedPets(player: Player)
	Local.RemoveAllEquippedPets(player)
	local equippedPets = Local.GetEquippedPets(player)
	if not equippedPets then
		return
	end
	Local.AddEquippedPets(player, equippedPets)
end

function Local.GetEquippedPets(player: Player): { [string]: boolean }
	local state = PlayerDataService.GetState(player)
	if not state then
		return {}
	end

	local equippedPets = state.equippedPets

	return equippedPets
end

function Local.RemoveAllEquippedPets(player: Player)
	local folder = PlayerPets:FindFirstChild(player.Name)

	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			child:Destroy()
		end
	end
end

function Local.AddEquippedPets(player: Player, equippedPets: { [string]: boolean })
	local folder = PlayerPets:FindFirstChild(player.Name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = player.Name
		folder.Parent = PlayerPets
	end

	for petName, isEquipped in pairs(equippedPets) do
		if petName and isEquipped == true then
			local pet = PetsFolder:WaitForChild(petName)
			if not pet then
				warn("Pet model not found in ReplicatedStorage: " .. petName)
				return
			end

			local petClone = PetsFolder:WaitForChild(petName):Clone()
			petClone.Parent = folder
		end
	end
end

return Shared
