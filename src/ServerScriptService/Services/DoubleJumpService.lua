local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.PlayerData.UpdateDoubleJump.OnServerEvent:Connect(Shared.ToggleSetting)
end

function Shared.ToggleSetting(player: Player)
	local state: PlayerData.PlayerData = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local currentValue = state.disableDoubleJump
	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateDoubleJump",
		value = not currentValue,
	}

	PlayerDataService.UpdateState(player, action)
end

return Shared
