local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local DebrisService = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local StateController = require(script.Parent.StateController)
local GuiController = require(script.Parent.GuiController)
local SoundsConfig = require(ReplicatedStorage.Configs.Sounds)

local GetStoreItemInfoRF = ReplicatedStorage:WaitForChild("GetStoreItemInfoRF")

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage.Remotes

local Gui = GuiController.Guis.TopTwo.Frame.Coins
local CoinsLabel = Gui.CoinsLabel
local PurchaseButton = Gui.PurchaseButton

local Local = {}
local Shared = {}

-- Table to track which coins have been collected by this player
Local.CollectedCoins = {}

function Shared.OnStart()
	Local.UpdateCoinsGui()
	Local.SetupCoinsTouched()
	Local.SetupPurchaseCoinButton()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateCoinCount" then
			Local.UpdateCoinsGui()
		end

		if action.type == "UpdateStage" then
			local state = StateController.GetState()
			if not state then
				return
			end

			if state.stage == 0 then
				-- Reset the collected coins
				Local.ResetCollectedCoin()
			end
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
				Local.SetupCoinTouched(index, coin)
			end
		end
	end)
end

function Local.SetupCoinTouched(index, coin)
	-- Create a player-specific coin instance
	local playerCoin = coin:Clone()
	playerCoin.Name = "PlayerCoin_" .. index
	playerCoin.Position = coin.Position
	playerCoin.Parent = coin.Parent

	-- Make the original coin invisible to this player
	coin.LocalTransparencyModifier = 1

	-- Set up touch detection for the player's character
	local touchConnection
	touchConnection = playerCoin.Touched:Connect(function(hit)
		local character = player.Character
		if not character then
			return
		end

		-- Check if the player's character touched the coin
		if hit:IsDescendantOf(character) then
			-- Disconnect the touch event to prevent multiple triggers
			touchConnection:Disconnect()

			-- Hide the coin for this player only
			playerCoin.Transparency = 1
			playerCoin.CanCollide = false

			-- Track that this coin has been collected
			Local.CollectedCoins[index] = {
				coin = coin,
				playerCoin = playerCoin,
			}

			-- Call the collect coin function
			Local.CollectCoin()
		end
	end)
end

function Local.CollectCoin()
	Remotes.CoinCollected:FireServer()
	Local.ShowWorldText()
	SoundsConfig.PlaySound("CoinCollect")
end

Local.ShowWorldText = function()
	local char = player.Character
	if not char then
		return
	end

	local head = char:FindFirstChild("Head")
	if not head then
		return
	end

	local function floatText(head, txt, time)
		-- 1) Billboard container
		local bill = Instance.new("BillboardGui")
		bill.Adornee = head
		bill.AlwaysOnTop = true
		bill.Size = UDim2.new(0, 200, 0, 50)
		bill.StudsOffset = Vector3.new(0, 2, 0)
		bill.Parent = head

		-- 2) TextLabel child
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = txt
		label.TextScaled = true
		label.Font = Enum.Font.SourceSansBold
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = bill

		-- auto-cleanup
		DebrisService:AddItem(bill, time)

		-- tween info
		local ti = TweenInfo.new(time, Enum.EasingStyle.Linear)

		-- 3a) float up
		TweenService:Create(bill, ti, {
			StudsOffset = Vector3.new(0, 8, 0),
		}):Play()

		-- 3b) fade out text
		TweenService:Create(label, ti, {
			TextTransparency = 1,
		}):Play()
	end

	-- example usage: pop “+100” for 1.2 seconds
	floatText(head, "+100", 1.2)
end

Local.ResetCollectedCoin = function()
	-- Reset all collected coins
	for index, coinData in pairs(Local.CollectedCoins) do
		local originalCoin = coinData.coin
		local playerCoin = coinData.playerCoin

		-- If the player coin still exists, destroy it
		if playerCoin and playerCoin:IsDescendantOf(game) then
			playerCoin:Destroy()
		end

		-- If the original coin still exists, make it visible again
		if originalCoin and originalCoin:IsDescendantOf(game) then
			originalCoin.LocalTransparencyModifier = 0

			-- Set up a new player coin
			Local.SetupCoinTouched(index, originalCoin)
		end
	end

	-- Reset the collected coins table
	Local.CollectedCoins = {}
end

function Local.SetupPurchaseCoinButton()
	PurchaseButton.Activated:Connect(function()
		Shared.PurchaseCoins(1000)
	end)
end

function Shared.PurchaseCoins(amount: number)
	if amount ~= 1000 then
		warn("That amount is not supported for purchase:", amount)
		return
	end

	local storeItemName = tostring(amount) .. " Coins"
	local storeItemInfo = GetStoreItemInfoRF:InvokeServer(storeItemName)

	if not storeItemInfo then
		warn("No store item info found for:", storeItemName)
		return
	end

	MarketplaceService:PromptProductPurchase(Player, storeItemInfo.Id)
end
return Shared
