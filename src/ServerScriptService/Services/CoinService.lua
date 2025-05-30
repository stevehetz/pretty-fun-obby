local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)
local PlayerDataService = require(script.Parent.PlayerDataService)
local GlobalDataService = require(script.Parent.GlobalDataService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.CoinCollected.OnServerEvent:Connect(Shared.OnUpdateCoinCount)
end

function Shared.OnUpdateCoinCount(player: Player)
	local state: PlayerData.PlayerData = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateCoinCount",
	}

	PlayerDataService.UpdateState(player, action)
	GlobalDataService.RecordCoinRank(player, state.coins)
end

return Shared
