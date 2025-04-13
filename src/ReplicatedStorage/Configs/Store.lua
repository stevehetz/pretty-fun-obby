local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

export type GamepassName = "Gravity Coil" | "Speed Coil"

export type StoreItemInfo = {
    Id: number | string, -- EXP-337322008051974488
    Name: string,
    Description: string,
    Price: number,
    Image: string
}

local Local = {}
local Shared = {}

Shared.Store = {
    Gamepasses = {
        {
            Id = 1157798560
        },
        {
            Id = 1157906298
        }
    },

    Products = {},

    Subscriptions = {
        {
            Id = "EXP-337322008051974488"
        }
    }
}

function Local.PopulateProductInfo(products: table, infoType: Enum.InfoType)
    for _, product in products do
        local info = MarketPlaceService:GetProductInfo(product.Id, infoType)
        product.Name = info.Name
        product.Description = info.Description
        product.Price = info.PriceInRobux
        product.Image = string.format("rbxassetid://%s", info.IconImageAssetId)
    end
end

function Local.GenerateStore()
    Local.PopulateProductInfo(Shared.Store.Gamepasses, Enum.InfoType.GamePass)

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

function Shared.GetGamepassInfo(id: string): StoreItemInfo
    for _, gamepassInfo in Shared.Store.Gamepasses do
        if gamepassInfo.Id == id or gamepassInfo.Name == id then
            return gamepassInfo
        end
    end
end

function Shared.DoesPlayerOwnGamepass(data, id: number | string): boolean
    id = Shared.GetGamepassInfo(id).Id
    return data.gamepasses[tostring(id)]
end

return Shared