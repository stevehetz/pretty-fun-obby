local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)
local RebirthService = require(ServerScriptService.Services.RebirthService)

local Local = {}
local Shared = {}

local playerDebounce = {}

Shared.OnStart = function()
	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		Local.SetupPortal(player)
	end)
end

Local.SetupPortal = function(player: Player)
	local RetryPortal = Workspace:FindFirstChild("RetryPortal")
	if not RetryPortal then
		return
	end

	for _, descendant in Workspace.RetryPortal:GetDescendants() do
		if descendant.Name == "Inside" then
			descendant.Touched:Connect(function(otherPart: BasePart)
				local player = Players:GetPlayerFromCharacter(otherPart.Parent)

				if player and not playerDebounce[player.UserId] then
					-- Set debounce for this player
					playerDebounce[player.UserId] = true

					RebirthService.Rebirth(player)

					task.delay(3, function()
						if playerDebounce[player.UserId] then
							playerDebounce[player.UserId] = nil
						end
					end)
				end
			end)
		end
	end
end

return Shared
