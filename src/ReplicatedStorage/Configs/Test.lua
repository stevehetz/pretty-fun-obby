local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Local = {}
local Shared = {}

Shared.Players = {
	ra1n_zer0 = {
		UserId = 6164663905,
		Name = "ra1n_zer0",
	},
	ra1n_test1 = {
		UserId = 8318796209,
		Name = "ra1n_test1",
	},
	ra1n_test2 = {
		UserId = 8398047634,
		Name = "ra1n_test2",
	},
	ra1n_test3 = {
		UserId = 8427812834,
		Name = "ra1n_test3",
	},
}

function Shared.IsDev(playerName: string): boolean
	for _, player in pairs(Shared.Players) do
		if player.Name == playerName then
			return true
		end
	end

	return false
end

return Shared
