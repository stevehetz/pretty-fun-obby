local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)
local StoreConfig = require(ReplicatedStorage.Configs.Store)
local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Players.UserSubscriptionStatusChanged:Connect(Local.ProcessSubscription)
	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		Local.ProcessSubscription(player, StoreConfig.Store.Subscriptions[1].Id)
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

return Shared