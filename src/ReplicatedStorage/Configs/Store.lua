local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

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

local Local = {}
local Shared = {}

Shared.Store = {
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

function Shared.IsGamepassTool(id: number | string): boolean
	for _, gamepassInfo in Shared.Store.Gamepasses do
		if gamepassInfo.Id == id or gamepassInfo.Name == id then
			return gamepassInfo.IsTool or false
		end
	end

	return false
end

function Shared.IsGamepassPet(id: number | string): boolean
	for _, gamepassInfo in Shared.Store.Gamepasses do
		if gamepassInfo.Id == id or gamepassInfo.Name == id then
			return gamepassInfo.IsPet or false
		end
	end

	return false
end

function Local.PopulateProductInfo(products: table, infoType: Enum.InfoType)
	for _, product in products do
		-- print("Calling product info from Marketplace service", product.Id, product.Name)
		local info = MarketPlaceService:GetProductInfo(product.Id, infoType)
		product.Name = info.Name
		product.Description = info.Description
		product.Price = info.PriceInRobux
		product.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
	end
end

function Local.GenerateStore()
	Local.PopulateProductInfo(Shared.Store.Gamepasses, Enum.InfoType.GamePass)
	Local.PopulateProductInfo(Shared.Store.Products, Enum.InfoType.Product)

	local isClient = RunService:IsClient()
	if isClient then
		for _, subscription in Shared.Store.Subscriptions do
			local info = MarketPlaceService:GetSubscriptionProductInfoAsync(subscription.Id)
			subscription.Name = info.Name
			subscription.Description = info.Description
			subscription.Price = info.Price
			subscription.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
		end
	end
end

Local.GenerateStore()

function Shared.GetStoreItemInfo(id: string): StoreItemInfo
	for _, gamepassInfo in Shared.Store.Gamepasses do
		if gamepassInfo.Id == id or gamepassInfo.Name == id then
			return gamepassInfo
		end
	end

	for _, productInfo in Shared.Store.Products do
		if productInfo.Id == id or productInfo.Name == id then
			return productInfo
		end
	end
end

function Shared.DoesPlayerOwnGamepass(data, id: number | string): boolean
	id = Shared.GetStoreItemInfo(id).Id
	return data.gamepasses[tostring(id)]
end

return Shared
