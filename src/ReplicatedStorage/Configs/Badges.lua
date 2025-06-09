local BadgeService = game:GetService("BadgeService")

type BadgeInfo = {
	Id: number,
	Name: string,
	Description: string,
	IconImageId: string,
	IsEnabled: boolean,
}

export type BadgeName = "Completed World 1" | "Completed World 2" | "Completed World 3" | "Supporter"

local BADGE_IDS = {
	1210932246765514, -- Completed World 1
	4139536495010938, -- Completed World 2
	3770682842619607, -- Completed World 3
	3173699013596688, -- Supporter
}

local BadgeInfo: { BadgeInfo } = {}

local Local = {}
local Shared = {}

function Local.CreateBadges()
	for _, id in BADGE_IDS do
		local success, info = pcall(function()
			return BadgeService:GetBadgeInfoAsync(id)
		end)
		if not success then
			continue
		end

		if info then
			info.Id = id
			table.insert(BadgeInfo, info)
		end
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
	if not info then
		return
	end

	local id = info.Id

	local hasBadgeSuccess, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, id)
	end)

	if not hasBadgeSuccess or hasBadge then
		return
	end

	pcall(function()
		BadgeService:AwardBadge(player.UserId, id)
	end)
end

return Shared
