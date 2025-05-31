local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local PlayerData = require(ReplicatedStorage.PlayerData)
local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local StoreConfig = require(ServerStorage.Configs.Store)

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

local playerDebounce = {}

Local.DonateProducts = {}

Shared.OnStart = function()
	Local.DonateProducts.Donate100 = StoreConfig.GetStoreItemInfo("Donate 100")
	Local.DonateProducts.Donate1000 = StoreConfig.GetStoreItemInfo("Donate 1000")
	Local.DonateProducts.Donate10000 = StoreConfig.GetStoreItemInfo("Donate 10000")

	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		local playerState = PlayerDataService.GetState(player)
		if not playerState then
			return
		end
		Local.SetupSigns(player, playerState)
	end)
end

Local.SetupSigns = function(player: Player, initialState: PlayerData.PlayerData)
	local DonateFolder = Workspace:FindFirstChild("Donate")
	if not DonateFolder then
		return
	end

	print(Local.DonateProducts)

	for _, donateSign in DonateFolder:GetChildren() do
		donateSign.Touched:Connect(function(otherPart: BasePart)
			local player = Players:GetPlayerFromCharacter(otherPart.Parent)

			if player and not playerDebounce[player.UserId] then
				playerDebounce[player.UserId] = true

				local productInfo = Local.DonateProducts[donateSign.Name]

				if not productInfo then
					warn("No product info found for: " .. donateSign.Name)
					playerDebounce[player.UserId] = nil
					return
				end

				local success, errorMessage = pcall(function()
					MarketplaceService:PromptProductPurchase(player, productInfo.Id)
				end)
				if not success then
					warn("Failed to prompt product purchase for " .. donateSign.Name .. ": " .. errorMessage)
					playerDebounce[player.UserId] = nil
					return
				end

				-- Reset the debounce after 3 seconds
				-- This is needed in case teleport fails or player stays in range
				task.delay(3, function()
					if playerDebounce[player.UserId] then
						playerDebounce[player.UserId] = nil
					end
				end)
			end
		end)
	end
end

return Shared
