local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ToolsService = require(script.Parent.ToolsService)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)
local StoreConfig = require(ReplicatedStorage.Configs.Store)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(Local.PurchaseGamepass)

	Players.UserSubscriptionStatusChanged:Connect(Local.ProcessSubscription)
	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		Local.ProcessSubscription(player, StoreConfig.Store.Subscriptions[1].Id)
		Local.ProcessGamepassPurchasedFromWebsite(player)
	end)
end

function Local.IsPlayerSubscribed(player: Player, id: string): boolean
	local success, doesOwnSubscription = pcall(function()
		return MarketplaceService:GetUserSubscriptionStatusAsync(player, id).IsSubscribed
	end)

	if not success then return end

	return doesOwnSubscription
end

function Local.ProcessSubscription(player: Player, id: string)
	local state = PlayerDataService.GetState(player)
	if not state then return end

	local isSubscribed = Local.IsPlayerSubscribed(player, id)

	local isDataSynced = isSubscribed == state.vip

	if not isDataSynced then
		local action: PlayerDataService.UpdateStateAction = {
			type = "UpdateVip",
			value = isSubscribed
		}
		PlayerDataService.UpdateState(player, action)
	end
	Remotes.UpdateVip:FireAllClients(player, isSubscribed)

	if isSubscribed then
		BadgesConfig.RewardBadge(player, "Supporter")
	end
end

function Local.PurchaseGamepass(player: Player, id: number, didPurchase: boolean)
	if not didPurchase then return end

	local state = PlayerDataService.GetState(player)
	if not state then return end

	local ownsGamepass = StoreConfig.DoesPlayerOwnGamepass(state, id)
	if ownsGamepass then return end

	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateGamepass",
		value = true,
		gamepassId = id
	}
	PlayerDataService.UpdateState(player, action)
	BadgesConfig.RewardBadge(player, "Supporter")

	local gamepassInfo = StoreConfig.GetGamepassInfo(id)
	ToolsService.GiveTool(player, gamepassInfo.Name)
	
end

function Local.ProcessGamepassPurchasedFromWebsite(player: Player)
	for _, gamepassInfo in StoreConfig.Store.Gamepasses do
		local ownsGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassInfo.Id)
		if ownsGamepass then
			Local.PurchaseGamepass(player, gamepassInfo.Id, true)
		end
	end
end

return Shared