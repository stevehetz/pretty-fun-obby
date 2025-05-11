local Local = {}
local Shared = {}

function Shared.Setup(rig, damageParts, damageAmount, damageCooldown)
	local canDamage = true
	for _, part in pairs(rig:GetDescendants()) do
		if part:IsA("BasePart") and table.find(damageParts, part.Name) then
			part.Touched:Connect(function(hit)
				-- Check if the part that was touched belongs to a player
				local character = hit.Parent
				local player = game.Players:GetPlayerFromCharacter(character)

				-- Only proceed if it's a player and we can damage
				if player and canDamage then
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
