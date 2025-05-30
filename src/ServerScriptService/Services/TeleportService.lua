local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataService = require(script.Parent.PlayerDataService)

local Remotes = ReplicatedStorage.Remotes

local Local = {}
local Shared = {}

function Shared.OnStart()
	Remotes.PlayerData.OneTimePass.OnServerEvent:Connect(function(player: Player, cost: number)
		print("OneTimePass event triggered for player: ", player.Name)
		cost = cost or 1000 -- Default cost if not provided

		if not player or not player:IsA("Player") then
			return
		end

		local state = PlayerDataService.GetState(player)
		if not state then
			warn("Player state not found for player: ", player.Name)
			return
		end

		local coins = state.coins or 0
		print("Current coins for player: ", player.Name, " is ", coins)
		if coins < cost then
			warn("Not enough coins for player: ", player.Name)
			return
		end

		-- Deduct the cost from player's coins
		local action = {
			type = "UpdateCoinCount",
			value = -cost,
		}

		PlayerDataService.UpdateState(player, action)

		-- Update the one-time pass status
		local action = {
			type = "UpdateOneTimePass",
			value = true,
		}

		PlayerDataService.UpdateState(player, action)
	end)
end

return Shared
