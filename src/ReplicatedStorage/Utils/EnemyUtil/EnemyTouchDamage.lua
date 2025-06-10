local Local = {}
local Shared = {}

-- Store enemy configurations by key
local enemyConfigs = {}
local nextConfigKey = 1

-- Store a config and return its key
function Shared.StoreConfig(config)
	local key = nextConfigKey
	enemyConfigs[key] = config
	nextConfigKey = nextConfigKey + 1
	return key
end

-- Get a config by key
function Shared.GetConfig(key)
	return enemyConfigs[key]
end

function Shared.Setup(rig, damageParts, damageAmount, damageCooldown, config)
	-- Store the config if it's not already stored
	if config and not rig:GetAttribute("ConfigKey") then
		local configKey = Shared.StoreConfig(config)
		rig:SetAttribute("ConfigKey", configKey)
	end

	local canDamage = true
	for _, part in pairs(rig:GetDescendants()) do
		if part:IsA("BasePart") and table.find(damageParts, part.Name) then
			part.Touched:Connect(function(hit)
				-- Check if the part that was touched belongs to a player
				local character = hit.Parent
				local player = game.Players:GetPlayerFromCharacter(character)

				-- Get the latest config from storage using the ConfigKey attribute
				local currentConfig = config
				if rig:GetAttribute("ConfigKey") then
					currentConfig = Shared.GetConfig(rig:GetAttribute("ConfigKey"))
				end

				-- Only proceed if it's a player, we can damage, and the enemy is not knocked over
				if player and canDamage and not (currentConfig and currentConfig.isKnockedOver) then
					local humanoid = character:FindFirstChild("Humanoid")

					if humanoid and humanoid.Health > 0 then
						-- Apply damage
						humanoid:TakeDamage(damageAmount)
						print("Damaged player " .. player.Name .. " for " .. damageAmount .. " health")

						-- Set cooldown
						canDamage = false
						task.delay(damageCooldown, function()
							canDamage = true
						end)
					end
				end
			end)
		end
	end
end

return Shared
