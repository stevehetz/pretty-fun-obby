local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PlayerDataService = require(script.Parent.PlayerDataService)

type PartEffect = "Kill" | "Death" | "Damage"

local PART_EFFECTS = {
	"Kill",
	"Death",
	"Damage",
}

local PlayerCooldown = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.SetupParts()
end

function Shared.UseEffect(player: Player, effect: PartEffect, part: BasePart)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local isKillEffect = effect == "Kill" or effect == "Death"
	local isDamageEffect = effect == "Damage"

	if isKillEffect then
		player:LoadCharacter()
	elseif isDamageEffect then
		local damage = part:GetAttribute("Damage") or 25
		humanoid.Health -= damage
	end
end

function Local.GetEffect(part: BasePart): PartEffect?
	local effect: PartEffect

	local isDamageEffect = part:GetAttribute("Damage")
	local effectFromName = table.find(PART_EFFECTS, part.Name)
	if isDamageEffect then
		effect = "Damage"
	elseif effectFromName then
		effect = PART_EFFECTS[effectFromName]
	end

	return effect
end

function Local.SetupParts()
	local descendants = Workspace:GetDescendants()
	for _, descendant: BasePart in descendants do
		local isPart = descendant:IsA("BasePart")
		if not isPart then
			continue
		end

		local effect = Local.GetEffect(descendant)
		if not effect then
			continue
		end

		descendant.Touched:Connect(function(otherPart: BasePart)
			local player = Players:GetPlayerFromCharacter(otherPart.Parent)
			if not player then
				return
			end

			local isOnCooldown = PlayerCooldown[player]
			if isOnCooldown then
				return
			end

			PlayerCooldown[player] = true
			task.delay(0.5, function()
				PlayerCooldown[player] = nil
			end)

			Shared.UseEffect(player, effect, descendant)
		end)
	end
end

return Shared
