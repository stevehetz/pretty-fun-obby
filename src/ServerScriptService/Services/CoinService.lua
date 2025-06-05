local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)
local PlayerDataService = require(script.Parent.PlayerDataService)
local GlobalDataService = require(script.Parent.GlobalDataService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

Local.CoinStoreItems = {
	["Trashcan"] = {
		name = "Trashcan",
		value = 300,
	},
}

function Shared.OnStart()
	Remotes.CoinCollected.OnServerEvent:Connect(Shared.OnUpdateCoinCount)
end

function Shared.OnUpdateCoinCount(player: Player, coinValue: number)
	coinValue = coinValue or 100

	local state: PlayerData.PlayerData = PlayerDataService.GetState(player)
	if not state then
		return
	end

	GlobalDataService.RecordCoinRank(player, state.coins + coinValue)

	task.wait(1)

	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateCoinCount",
		value = coinValue,
	}
	PlayerDataService.UpdateState(player, action)
end

function Shared.GetCoinStoreItemInfo(itemName: string)
	if Local.CoinStoreItems[itemName] then
		return Local.CoinStoreItems[itemName]
	end

	return nil
end

return Shared
