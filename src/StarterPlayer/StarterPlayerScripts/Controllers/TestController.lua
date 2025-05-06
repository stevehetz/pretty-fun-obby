local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local TestConfig = require(ReplicatedStorage.Configs.Test)

local Local = {}
local Shared = {}

function Shared.IsDev()
	if LocalPlayer then
		if TestConfig.IsDev(LocalPlayer.Name) then
			return true
		end
	end

	return false
end

return Shared
