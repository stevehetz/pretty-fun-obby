local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent.PlayerDataService)
local ToolsService = require(script.Parent.ToolsService)
local PetService = require(script.Parent.PetService)
local PetsConfig = require(ReplicatedStorage.Configs.Pets)
local BadgesConfig = require(ReplicatedStorage.Configs.Badges)
local StoreConfig = require(ReplicatedStorage.Configs.Store)
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

function Shared.OnStart()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(Local.PurchaseGamepass)
	MarketplaceService.ProcessReceipt = Local.PurchaseProduct

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

	if not success then
		return
	end

	return doesOwnSubscription
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

function Local.PurchaseGamepass(player: Player, id: number, didPurchase: boolean)
	if not didPurchase then
		return
	end

	local state = PlayerDataService.GetState(player)
	if not state then
		return
	end

	local ownsGamepass = StoreConfig.DoesPlayerOwnGamepass(state, id)
	if ownsGamepass then
		return
	end

	local action: PlayerDataService.UpdateStateAction = {
		type = "UpdateGamepass",
		value = true,
		gamepassId = id,
	}
	PlayerDataService.UpdateState(player, action)
	-- BadgesConfig.RewardBadge(player, "Supporter")

	-- Only do this for Tools (Gravity Coil, Speed Coil)
	if StoreConfig.IsGamepassTool(id) then
		local gamepassInfo = StoreConfig.GetStoreItemInfo(id)
		ToolsService.GiveTool(player, gamepassInfo.Name)
		return
	end

	if StoreConfig.IsGamepassPet(id) then
		local pet = PetsConfig.GetPetFromGamePassId(id)
		PetService.UpdateEquippedPets(player, pet)
	end
end

function Local.ProcessGamepassPurchasedFromWebsite(player: Player)
	for _, gamepassInfo in StoreConfig.Store.Gamepasses do
		-- print("Checking if player owns gamepass from website", gamepassInfo.Id, player.UserId)

		-- Check playersate if they own the gamepass
		local state = PlayerDataService.GetState(player)
		if not state then
			return
		end

		local ownsGamepass = StoreConfig.DoesPlayerOwnGamepass(state, gamepassInfo.Id)

		-- If the player already owns the gamepass, skip it
		if ownsGamepass then
			-- print("Player " .. player.Name .. " already owns gamepass " .. gamepassInfo.Name)
			continue
		end

		-- Player doesn't own gamepass, check if they purchased it from the website
		-- print("Checking if player " .. player.Name .. " owns gamepass " .. gamepassInfo.Name .. " from website")
		ownsGamepass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassInfo.Id)

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
	if is5Skips then
		local isVIP = state.vip
		local action: PlayerDataService.UpdateStateAction = {
			type = "EarnSkip",
			amount = isVIP and 10 or 5,
		}
		PlayerDataService.UpdateState(player, action)
		decision = Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local isTeleportWorld2 = productInfo.Name == "Teleport to World 2"
	if isTeleportWorld2 then
		print("Purchase Granted: Teleporting to World 2")

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

	-- BadgesConfig.RewardBadge(player, "Supporter")

	return decision
end

return Shared
