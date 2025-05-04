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
	Remotes.PlayerData.UpdateEquippedPet.OnServerEvent:Connect(function(player, pet: PetsConfig.PetInfo)
		print(player.Name, pet.Name)

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
	end)

	PlayerDataService.ProfileLoaded.Event:Connect(function(player)
		local state = PlayerDataService.GetState(player)
		print(state)
		Local.RefreshEquippedPets(player)
		-- local pet = PetsFolder:WaitForChild("HallowsSpider"):Clone()
		-- local pet = PetsFolder:WaitForChild("LilDemon"):Clone()
		-- local pet = PetsFolder:WaitForChild("Cerberus"):Clone()
		-- local pet = PetsFolder:WaitForChild("Dog"):Clone()
		-- local pet = PetsFolder:WaitForChild("Cat"):Clone()
		-- local pet = PetsFolder:WaitForChild("Fox"):Clone()
		-- local pet = PetsFolder:WaitForChild("Shark"):Clone()
		-- local pet = PetsFolder:WaitForChild("HallowsSpider"):Clone()
		-- local pet = PetsFolder:WaitForChild("Dominus Crystal"):Clone()
		-- local pet = PetsFolder:WaitForChild("Dragon"):Clone()
		-- local pet = PetsFolder:WaitForChild("Ice Dragon"):Clone()
		-- local pet = PetsFolder:WaitForChild("Galactic Overlord"):Clone()
		-- local pet = PetsFolder:WaitForChild("Sun Flare"):Clone()
		-- pet.Parent = folder
	end)

	Players.PlayerRemoving:Connect(function(player)
		local folder = PlayerPets:FindFirstChild(player.Name)
		if folder then
			folder:Destroy()
		end
	end)
end

Local.RefreshEquippedPets = function(player: Player)
	Local.RemoveAllEquippedPets(player)
	local equippedPets = Local.GetEquippedPets(player)
	if not equippedPets then
		return
	end
	Local.AddEquippedPets(player, equippedPets)
end

Local.GetEquippedPets = function(player: Player): { [string]: boolean }
	local state = PlayerDataService.GetState(player)
	if not state then
		return {}
	end

	local equippedPets = state.equippedPets

	print("equipped pets", state.equippedPets)

	return equippedPets
end

Local.RemoveAllEquippedPets = function(player: Player)
	local folder = PlayerPets:FindFirstChild(player.Name)

	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			print("Removing pet folder:", child.Name)
			child:Destroy()
		end
	end
end

Local.AddEquippedPets = function(player: Player, equippedPets: { [string]: boolean })
	local folder = PlayerPets:FindFirstChild(player.Name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = player.Name
		folder.Parent = PlayerPets
	end

	for petName, isEquipped in pairs(equippedPets) do
		if petName and isEquipped == true then
			print("Adding equipped pet:", petName)
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
