local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

export type GamepassName = "Gravity Coil" | "Speed Coil" | "Double Jump"

export type StoreItemInfo = {
	Id: number | string, -- EXP-337322008051974488
	Name: string,
	Description: string,
	Price: number,
	Image: string,
	IsTool: boolean?,
	IsPet: boolean?,
}

local _store = {
	Gamepasses = {
		{
			Id = 1157798560, -- Gravity Coil
			IsTool = true,
		},
		{
			Id = 1157906298, -- Speed Coil
			IsTool = true,
		},
		{
			Id = 1160545563, -- Double Jump
			IsPet = true,
		},
		{
			Id = 1198006484, --  Fox
			IsPet = true,
		},
		{
			Id = 1197084528, -- Dominus Crystal
			IsPet = true,
		},
		{
			Id = 1199016473, -- Dragon
			IsPet = true,
		},
		{
			Id = 1198272735, -- Ice Dragon
			IsPet = true,
		},
		{
			Id = 1196970764, -- Cerberus
			IsPet = true,
		},
		{
			Id = 1198896690, -- Galactic Overlord
			IsPet = true,
		},
		{
			Id = 1197718750, -- Sun Flare
			IsPet = true,
		},
	},

	Products = {
		{
			Id = 3265508606, -- 5 skips
		},
		{
			Id = 3275590834, -- Teleport to World 2
		},
	},

	Subscriptions = {
		{
			Id = "EXP-337322008051974488",
		},
	},
}

local Local = {}
local Shared = {}

Local.StoreItemInfoReady = false

Local.LoadStoreInfo()

function Local.LoadStoreInfo()
	-- Load gamepass info
	for _, product in Local.Store.Gamepasses do
		local info = MarketplaceService:GetProductInfo(product.Id, Enum.InfoType.GamePass)
		product.Name = info.Name
		product.Description = info.Description
		product.Price = info.PriceInRobux
		product.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
	end

	-- Load product info
	for _, product in Local.Store.Products do
		local info = MarketplaceService:GetProductInfo(product.Id, Enum.InfoType.Product)
		product.Name = info.Name
		product.Description = info.Description
		product.Price = info.PriceInRobux
		product.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
	end

	-- Load subscription info
	local isClient = RunService:IsClient()
	if isClient then
		for _, subscription in Local.Store.Subscriptions do
			local info = MarketplaceService:GetSubscriptionProductInfoAsync(subscription.Id)
			subscription.Name = info.Name
			subscription.Description = info.Description
			subscription.Price = info.Price
			subscription.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
		end
	end

	Local.StoreItemInfoReady = true
end

function Shared.GetStore()
	while not Local.StoreItemInfoReady do
		task.wait(0.1) -- Small wait to prevent tight loops
	end
	return Local.Store
end

function Shared.GetStoreItemInfo(id: number | string): StoreItemInfo
	local Store = Shared.GetStore()

	for _, gamepassInfo in Store.Gamepasses do
		if gamepassInfo.Id == id or gamepassInfo.Name == id then
			return gamepassInfo
		end
	end

	for _, productInfo in Store.Products do
		if productInfo.Id == id or productInfo.Name == id then
			return productInfo
		end
	end

	for _, subscriptionInfo in Store.Subscriptions do
		if subscriptionInfo.Id == id or subscriptionInfo.Name == id then
			return subscriptionInfo
		end
	end
end

function Shared.IsGamepassTool(id: number | string): boolean
	for _, gamepassInfo in Shared.GetStore().Gamepasses do
		if gamepassInfo.Id == id or gamepassInfo.Name == id then
			return gamepassInfo.IsTool or false
		end
	end

	return false
end

function Shared.IsGamepassPet(id: number | string): boolean
	for _, gamepassInfo in Shared.GetStore().Gamepasses do
		if gamepassInfo.Id == id or gamepassInfo.Name == id then
			return gamepassInfo.IsPet or false
		end
	end

	return false
end

return Shared
