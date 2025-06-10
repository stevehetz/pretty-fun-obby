local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

export type GamepassName = "Double Jump" | "Gravity Coil" | "Speed Coil"

export type StoreItemInfo = {
	Id: number | string, -- EXP-337322008051974488
	Name: string,
	Description: string,
	Price: number,
	Image: string,
	IsGamepass: boolean?,
	IsProduct: boolean?,
	IsSubscription: boolean?,
	IsTool: boolean?,
	IsPet: boolean?,
	IsPass: boolean?,
}

local _store = {
	Gamepasses = {
		{
			Id = 1160545563, -- Double Jump
			-- Id = 1234166662, -- Double Jump (Test)
			IsAbility = true,
		},
		{
			Id = 1157798560, -- Gravity Coil
			IsTool = true,
		},
		{
			Id = 1157906298, -- Speed Coil
			IsTool = true,
		},
		-- {
		-- 	Id = 1198006484, --  Fox
		-- 	IsPet = true,
		-- },
		-- {
		-- 	Id = 1197084528, -- Dominus Crystal
		-- 	IsPet = true,
		-- },
		{
			Id = 1199016473, -- Dragon
			IsPet = true,
		},
		{
			Id = 1198272735, -- Ice Dragon
			IsPet = true,
		},
		-- {
		-- 	Id = 1196970764, -- Cerberus
		-- 	IsPet = true,
		-- },
		-- {
		-- 	Id = 1198896690, -- Galactic Overlord
		-- 	IsPet = true,
		-- },
		-- {
		-- 	Id = 1197718750, -- Sun Flare
		-- 	IsPet = true,
		-- },
		{
			Id = 1234640489, -- Permanent World Pass
			-- Id = 1246700401, -- Permanent World Pass (Test)
			IsPass = true,
		},
		{
			Id = 1255668315, -- Sword
			IsTool = true,
		},
	},

	Products = {
		{
			Id = 3265508606, -- 5 skips
		},
		{
			Id = 3275590834, -- Teleport to World 2
		},
		{
			Id = 3293766409, -- 1000 Coins
		},
		{
			Id = 3296554956, -- Donate 100 Robux
		},
		{
			Id = 3296555455, -- Donate 1000 Robux
		},
		{
			Id = 3296555939, -- Donate 10000 Robux
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

function Local.LoadStoreInfo()
	-- Load store info in a separate thread
	task.spawn(function()
		-- Load gamepass info with retry
		Local.RetryUntilSuccess(function()
			for _, product in _store.Gamepasses do
				local info = MarketplaceService:GetProductInfo(product.Id, Enum.InfoType.GamePass)
				product.IsGamepass = true
				product.Name = info.Name
				product.Description = info.Description
				product.Price = info.PriceInRobux
				product.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
			end
			return true
		end, "Failed to load gamepass info:")()

		-- Load product info with retry
		Local.RetryUntilSuccess(function()
			for _, product in _store.Products do
				local info = MarketplaceService:GetProductInfo(product.Id, Enum.InfoType.Product)
				product.IsProduct = true
				product.Name = info.Name
				product.Description = info.Description
				product.Price = info.PriceInRobux
				product.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
			end
			return true
		end, "Failed to load product info:")()

		-- Load subscription info with retry
		local isClient = RunService:IsClient()
		if isClient then
			Local.RetryUntilSuccess(function()
				for _, subscription in _store.Subscriptions do
					local info = MarketplaceService:GetSubscriptionProductInfoAsync(subscription.Id)
					subscription.IsSubscription = true
					subscription.Name = info.Name
					subscription.Description = info.Description
					subscription.Price = info.Price
					subscription.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
				end
				return true
			end, "Failed to load subscription info:")()
		end

		-- All data has been successfully loaded
		Local.StoreItemInfoReady = true
	end)
end

Local.LoadStoreInfo()

function Shared.GetStore()
	while not Local.StoreItemInfoReady do
		task.wait(0.1) -- Small wait to prevent tight loops
	end
	return _store
end

function Shared.GetStoreItemInfo(idOrName: number | string): StoreItemInfo
	local Store = Shared.GetStore()

	for _, gamepassInfo in Store.Gamepasses do
		if gamepassInfo.Id == idOrName or gamepassInfo.Name == idOrName then
			return gamepassInfo
		end
	end

	for _, productInfo in Store.Products do
		if productInfo.Id == idOrName or productInfo.Name == idOrName then
			return productInfo
		end
	end

	for _, subscriptionInfo in Store.Subscriptions do
		if subscriptionInfo.Id == idOrName or subscriptionInfo.Name == idOrName then
			return subscriptionInfo
		end
	end
end

function Shared.IsGamepassTool(idOrName: number | string): boolean
	for _, gamepassInfo in Shared.GetStore().Gamepasses do
		if gamepassInfo.Id == idOrName or gamepassInfo.Name == idOrName then
			return gamepassInfo.IsTool or false
		end
	end

	return false
end

function Shared.IsGamepassPet(idOrName: number | string): boolean
	for _, gamepassInfo in Shared.GetStore().Gamepasses do
		if gamepassInfo.Id == idOrName or gamepassInfo.Name == idOrName then
			return gamepassInfo.IsPet or false
		end
	end

	return false
end

return Shared
