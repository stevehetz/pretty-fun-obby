local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoreConfig = require(ReplicatedStorage.Configs.Store)

export type PetInfo = {
	Name: string,
	Description: string?,
	Price: number?,
	Image: string?,
}

local Local = {}
local Shared = {}

Local.Pets = {
	{
		Name = "Dog",
	},
	{
		Name = "Cat",
	},
	{
		Name = "Fox",
	},
	-- {
	-- 	Name = "Shark",
	-- },
	-- {
	-- 	Name = "HallowsSpider",
	-- },
	{
		Name = "Dominus Crystal",
	},
	{
		Name = "Dragon",
	},
	{
		Name = "Ice Dragon",
	},
	-- {
	-- 	Name = "LilDemon",
	-- },
	{
		Name = "Cerberus",
	},
	{
		Name = "Galactic Overlord",
	},
	{
		Name = "Sun Flare",
	},
}

function Local.AddProductInfo()
	-- loop through petss
	for _, pet in ipairs(Local.Pets) do
		local petName = pet.Name
		local productInfo = StoreConfig.GetStoreItemInfo(petName)

		if productInfo then
			pet.GamePassId = productInfo.Id
			pet.Name = productInfo.Name
			pet.Description = productInfo.Description
			pet.Price = productInfo.Price
			pet.Image = string.format("rbxassetid://%s", productInfo.Image)
		end
	end

	Shared.Pets = Local.Pets
end

Local.AddProductInfo()

function Shared.GetPets(): { PetInfo }
	return Local.Pets
end

function Shared.GetPetFromGamePassId(id: number): PetInfo?
	for _, pet in ipairs(Local.Pets) do
		if pet.GamePassId == id then
			return pet
		end
	end

	return nil
end

return Shared
