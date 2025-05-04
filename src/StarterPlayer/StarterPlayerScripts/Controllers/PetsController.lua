local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PetsConfig = require(ReplicatedStorage.Configs.Pets)
local StateController = require(script.Parent.StateController)
local Remotes = ReplicatedStorage.Remotes.PlayerData

local Local = {}
local Shared = {}

function Shared.OnStart()
	-- StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
	-- 	if action.type == "UpdateEquippedPets" then
	-- 		print(action)
	-- 	end
	-- end)
end

function Shared.ToggleEquippedPet(pet: PetsConfig.PetInfo)
	Remotes.UpdateEquippedPet:FireServer(pet)
end

return Shared
