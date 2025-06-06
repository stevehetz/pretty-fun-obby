local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)
local PlayerDataService = require(script.Parent.PlayerDataService)
local GlobalDataService = require(script.Parent.GlobalDataService)
local ToolsService = require(script.Parent.ToolsService)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

Local.CoinStoreItems = {
	["Trashcan"] = {
		Name = "Trashcan",
		Value = 300,
		IsTool = true,
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

function Shared.Purchase(player: Player, itemName: string)
	local itemInfo = Shared.GetCoinStoreItemInfo(itemName)

	if not itemInfo then
		warn("Item not found in coin store:", itemName)
		return
	end

	local state: PlayerData.PlayerData = PlayerDataService.GetState(player)

	if state.coins < itemInfo.Value then
		warn("Not enough coins to purchase item:", itemName)
		return
	end

	if itemInfo.IsTool then
		local didPurchase = Local.PurchaseTool(player, itemInfo)
		return didPurchase
	end
end

function Local.PurchaseTool(player: Player, itemInfo)
	-- Check if item is in backpack
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if backpack:FindFirstChild(itemInfo.Name) then
		warn("Player already owns item:", itemInfo.Name)
		return
	end

	-- Give the tool to the player
	ToolsService.GiveTool(player, itemInfo.Name)

	-- Deduct coins
	local coinCountAction: PlayerDataService.UpdateStateAction = {
		type = "UpdateCoinCount",
		value = -itemInfo.Value,
	}
	PlayerDataService.UpdateState(player, coinCountAction)

	-- Set hasTrashcan player state to true
	local hasTrashcanAction: PlayerDataService.UpdateStateAction = {
		type = "UpdateHasTrashcan",
		value = true,
	}
	PlayerDataService.UpdateState(player, hasTrashcanAction)

	return true
end

return Shared
