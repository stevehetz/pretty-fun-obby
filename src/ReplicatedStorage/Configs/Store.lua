local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

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
    Gamepasses = {},

    Products = {},

    Subscriptions = {
        {
            Id = "EXP-337322008051974488"
        }
    }
}

function Local.GenerateStore()
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

return Shared