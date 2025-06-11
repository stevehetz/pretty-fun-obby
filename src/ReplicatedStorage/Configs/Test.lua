local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Local = {}
local Shared = {}

Shared.Developers = {
	ra1n_zer0 = {
		UserId = 6164663905,
		Name = "ra1n_zer0",
	},
	ra1n_test2 = {
		UserId = 8398047634,
		Name = "ra1n_test2",
	},
	-- ra1n_test3 = {
	-- 	UserId = 8427812834,
	-- 	Name = "ra1n_test3",
	-- },
}

Shared.Testers = {
	ra1n_test1 = {
		UserId = 8318796209,
		Name = "ra1n_test1",
	},
	Cuaco218 = {
		UserId = 5527661621,
		Name = "Cuaco218",
	},
	Bruman1118 = {
		UserId = 6192083401,
		Name = "Bruman1118",
	},
	Bruman1151 = {
		UserId = 8278362441,
		Name = "Bruman1151",
	},
	TrashCanMan669 = {
		UserId = 8358751040,
		Name = "TrashCanMan669",
	},
}

function Shared.IsDev(playerName: string): boolean
	for _, player in pairs(Shared.Developers) do
		if player.Name == playerName then
			return true
		end
	end

	return false
end

function Shared.IsTester(playerName: string): boolean
	print("Shared.IsTester - Player Name: " .. playerName)
	for _, player in pairs(Shared.Testers) do
		if player.Name == playerName then
			print("Shared.IsTester - Found Tester: " .. player.Name)
			return true
		end
	end

	return false
end

return Shared
