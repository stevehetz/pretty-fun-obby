local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StateController = require(script.Parent.StateController)
local GuiController = require(script.Parent.GuiController)

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage.Remotes.PlayerData

local Gui = GuiController.Guis.TopTwo.Frame.Coins
local CoinsLabel = Gui.CoinsLabel

local Local = {}
local Shared = {}

Local.CollectedCoins = {}

function Shared.OnStart()
	Local.UpdateCoinsGui()
	Local.SetupCoinsTouched()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateCoinCount" then
			Local.UpdateCoinsGui()
		end
	end)
end

function Local.UpdateCoinsGui()
	local state = StateController.GetState()
	if not state then
		return
	end
	CoinsLabel.Text = state.coins
end

function Local.SetupCoinsTouched()
	local coinFolder = Workspace:WaitForChild("Coins")

	task.spawn(function()
		coinFolder:WaitForChild("Coin", 10)

		for index, coin in ipairs(coinFolder:GetChildren()) do
			if coin.Name == "Coin" then
				coin.Touched:Connect(function(hit)
					if Local.CollectedCoins[index] then
						return
					end

					Local.CollectedCoins[index] = true
					if hit:IsDescendantOf(Player.Character) then
						Shared.CollectCoin(index, coin)
					end
				end)
			end
		end
	end)
end

function Shared.CollectCoin(index, coin)
	Remotes.UpdateCoinCount:FireServer(coin)

	coin:Destroy()
end

return Shared
