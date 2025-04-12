local BadgeService = game:GetService("BadgeService")

type BadgeInfo = {
    Id: number,
    Name: string,
    Description: string,
    IconImageId: string,
    IsEnabled: boolean,
}

export type BadgeName = "Stage 10" | "Supporter" | "Rebirth"

local BADGE_IDS = {
    3296342849110739, -- Stage 10
    3173699013596688, -- Supporter
    4170857839321681, -- Rebirth
}

local BadgeInfo: { BadgeInfo } = {}

local Local = {}
local Shared = {}

function Local.CreateBadges()
    for _, id in BADGE_IDS do
        local success, info = pcall(function()
            return BadgeService:GetBadgeInfoAsync(id)
        end)
        if not success then continue end
        
        if info then
            info.Id = id
            table.insert(BadgeInfo, info)
        end

        print(BadgeInfo)
    end
end

Local.CreateBadges()

function Shared.GetBadgeInfoByName(name: BadgeName): BadgeInfo?
    for _, info in BadgeInfo do
        local isBadge = info.Name == name
        if isBadge then
            return info
        end
    end
end

function Shared.RewardBadge(player: Player, name: BadgeName)
    local info = Shared.GetBadgeInfoByName(name)
    if not info then return end

    
    local id = info.Id

    local hasBadgeSuccess, hasBadge = pcall(function()
        return BadgeService:UserHasBadgeAsync(player.UserId, id)
    end)

    if not hasBadgeSuccess or hasBadge then return end

    print("Awarding badge to player:", player.Name, "Badge ID:", id)

    pcall(function()
        return BadgeService:AwardBadge(player.UserId, id)
    end)
end

return Shared