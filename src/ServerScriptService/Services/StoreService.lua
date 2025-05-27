local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ToolsService = require(script.Parent.ToolsService)
local PetService = require(script.Parent.PetService)
local StoreConfig = require(ServerStorage.Configs.Store)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)
local Remotes = ReplicatedStorage.Remotes

type ReceiptInfo = {
	PurchaseId: number,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,
}

local Local = {}
local Shared = {}

-- Helper function to retry a function until it succeeds
function Local.RetryUntilSuccess(funcToRetry, errorMessage)
	return function()
		while true do
			local success, result = pcall(funcToRetry)

			if success then
				return result
			else
				warn(errorMessage, result)
				print("Retrying in 10 seconds...")
				task.wait(10)
			end
		end
	end
end

local GetStoreRF = Instance.new("RemoteFunction")
GetStoreRF.Name = "GetStoreRF"
GetStoreRF.Parent = ReplicatedStorage

local GetStoreItemInfoRF = Instance.new("RemoteFunction")
GetStoreItemInfoRF.Name = "GetStoreItemInfoRF"
GetStoreItemInfoRF.Parent = ReplicatedStorage

function Shared.OnStart()
	GetStoreRF.OnServerInvoke = StoreConfig.GetStore
	GetStoreItemInfoRF.OnServerInvoke = function(player: Player, id: number | string)
		return StoreConfig.GetStoreItemInfo(id)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(Local.PurchaseGamepass)
	MarketplaceService.ProcessReceipt = Local.PurchaseProduct

	Players.UserSubscriptionStatusChanged:Connect(Local.ProcessSubscription)

	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		task.spawn(function()
			Local.ProcessGamepassPurchasedFromWebsite(player)
			Local.ProcessSubscription(player, StoreConfig.GetStore().Subscriptions[1].Id)
		end)
	end)
end

function Local.ProcessGamepassPurchasedFromWebsite(player: Player)
	-- Check playersate if they own the gamepass
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	for _, gamepassInfo in StoreConfig.GetStore().Gamepasses do
		-- print("Checking if player owns gamepass from website", gamepassInfo.Id, player.UserId)

		local ownsGamepass = state.gamepasses[tostring(gamepassInfo.Id)] or false

		-- If the player already owns the gamepass, skip it
		if ownsGamepass then
			-- print("Player " .. player.Name .. " already owns gamepass " .. gamepassInfo.Name)
			continue
		end

		-- Player doesn't own gamepass, check if they purchased it from the website
		-- print("Checking if player " .. player.Name .. " owns gamepass " .. gamepassInfo.Name .. " from website")
		ownsGamepass = Local.RetryUntilSuccess(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassInfo.Id)
		end, "Failed to check if player owns gamepass from website:")()

		if ownsGamepass then
			print("Player " .. player.Name .. " purchased " .. gamepassInfo.Name .. " from website")
			-- They must have purchased it from the website
			-- Update the player data to reflect that they own the gamepass
			Local.PurchaseGamepass(player, gamepassInfo.Id, true)
		else
			-- print("Player " .. player.Name .. " does not own gamepass " .. gamepassInfo.Name)
		end
	end
end

function Local.PurchaseGamepass(player: Player, id: number, didPurchase: boolean)
	print("PurchaseGamepass", player.Name, id, didPurchase)
	if not didPurchase then
		return
	end

	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local ownsGamepass = state.gamepasses[tostring(id)] or false
	if ownsGamepass then
		return
	end

	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateGamepass",
		value = true,
		gamepassId = id,
	}
	PlayerDataService.UpdateState(player, action)

	if StoreConfig.IsGamepassTool(id) then
		print("Giving tool to player", player.Name, id)
		local gamepassInfo = StoreConfig.GetStoreItemInfo(id)
		ToolsService.GiveTool(player, gamepassInfo.Name, gamepassInfo.Id)
		return
	end

	if StoreConfig.IsGamepassPet(id) then
		local gamepassInfo = StoreConfig.GetStoreItemInfo(id)
		PetService.UpdateEquippedPets(player, gamepassInfo)
	end
end

function Local.PurchaseProduct(receiptInfo: ReceiptInfo)
	local decision = Enum.ProductPurchaseDecision.NotProcessedYet

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return decision
	end

	local state = PlayerDataService.GetState(player)
	if not state then
		return decision
	end

	local productInfo = StoreConfig.GetStoreItemInfo(receiptInfo.ProductId)
	if not productInfo then
		return decision
	end

	local is5Skips = productInfo.Name == "5 Skips"
	local isTeleportWorld2 = productInfo.Name == "Teleport to World 2"
	local is1000Coins = productInfo.Name == "1000 Coins"

	if is5Skips then
		local action: PlayerDataService.UpdateStateAction = {
			type = "EarnSkip",
			amount = 5,
		}
		PlayerDataService.UpdateState(player, action)
		decision = Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if isTeleportWorld2 then
		-- Get the WorldPortalService
		local WorldPortalService = require(script.Parent.WorldPortalService)

		-- Check if there's pending teleport info for this player
		if WorldPortalService.pendingTeleports and WorldPortalService.pendingTeleports[player.UserId] then
			local teleportInfo = WorldPortalService.pendingTeleports[player.UserId]

			-- Freeze the player so they can't move during teleport
			local character = player.Character
			if character and character:FindFirstChild("Humanoid") then
				local humanoid = character.Humanoid
				humanoid.WalkSpeed = 0
				humanoid.JumpHeight = 0
			end

			-- Teleport the player
			WorldPortalService.TeleportPlayer(player, teleportInfo.worldName, teleportInfo.placeId)

			-- Clear the pending teleport
			WorldPortalService.pendingTeleports[player.UserId] = nil
		end
		decision = Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if is1000Coins then
		local action: PlayerDataService.UpdateStateAction = {
			type = "UpdateCoinCount",
			value = 1000,
		}
		PlayerDataService.UpdateState(player, action)
		decision = Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- BadgesConfig.RewardBadge(player, "Supporter")

	return decision
end

function Local.ProcessSubscription(player: Player, id: string)
	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local isSubscribed = Local.IsPlayerSubscribed(player, id)

	local isDataSynced = isSubscribed == state.vip

	if not isDataSynced then
		local action: PlayerDataService.UpdateStateAction = {
			type = "UpdateVip",
			value = isSubscribed,
		}
		PlayerDataService.UpdateState(player, action)
	end
	Remotes.UpdateVip:FireAllClients(player, isSubscribed)

	if isSubscribed then
		BadgesConfig.RewardBadge(player, "Supporter")
	end
end

function Local.IsPlayerSubscribed(player: Player, id: string): boolean
	local doesOwnSubscription = Local.RetryUntilSuccess(function()
		return MarketplaceService:GetUserSubscriptionStatusAsync(player, id).IsSubscribed
	end, "Failed to check subscription status:")()

	return doesOwnSubscription
end

return Shared
