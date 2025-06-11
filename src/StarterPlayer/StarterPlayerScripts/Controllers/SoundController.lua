local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage.Configs.Sounds)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	local PlaySound = Remotes:WaitForChild("PlaySound")

	PlaySound.OnClientEvent:Connect(function(soundName)
		Sounds.PlaySound(soundName)
	end)
end

return Shared
