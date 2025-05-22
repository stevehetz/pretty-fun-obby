local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage.Remotes.PlayerData

local Local = {}
local Shared = {}

function Shared.Toggle()
	Remotes.UpdateDoubleJump:FireServer()
end

return Shared
