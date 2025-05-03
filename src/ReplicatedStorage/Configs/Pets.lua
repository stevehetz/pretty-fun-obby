local Local = {}
local Shared = {}

Shared.FreePets = {
	{
		Name = "Dog",
		Price = 0,
	},
	{
		Name = "Cat",
		Price = 0,
	},
}

Shared.PremiumPets = {}

Shared.Pets = {}

function Shared.OnStart()
	Local.SetupPets()
end

function LocalSetupPets()
	for _, freePets in ipairs(Shared.FreePets) do
		-- Add to Pets
		table.insert(Shared.Pets, freePets.Name)
	end

	for _, premiumPets in ipairs(Shared.PremiumPets) do
		-- Add to Pets
		table.insert(Shared.Pets, premiumPets.Name)
	end
end

return Shared
