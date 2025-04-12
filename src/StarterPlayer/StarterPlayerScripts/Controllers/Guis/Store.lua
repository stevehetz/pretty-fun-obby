local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local StoreConfig = require(ReplicatedStorage.Configs.Store)
local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)

local Gui = GuiController.Guis.Left
local Frame = Gui.Frame

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.GenerateStore()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		local isSubscription = action.type == "UpdateVip"
		if isSubscription then
			Local.UpdateButton(StoreConfig.Store.Subscriptions[1].Id, action.value)
		end
	end)
end

function Local.GenerateStore()
	 for _, info in StoreConfig.Store.Gamepasses do
		Local.SetupButton(info, true)
	 end

	 for _, info in StoreConfig.Store.Subscriptions do
		print(info)
		Local.SetupButton(info, false)
	 end
end

function Local.UpdateButton(id: string, isPurchased: boolean)
	local button: TextButton = Frame:FindFirstChild(id)

	if button then
		button.Visible = not isPurchased
	end
end

function Local.SetupButton(info: StoreConfig.StoreItemInfo, isGamepass: boolean?)
	local button: TextButton = Frame:FindFirstChild(info.Name:gsub(" ", ""))
	print(button)
	if not button then return end

	local isOwned = if isGamepass then true else StateController.GetState().vip -- Todo

	button.Name = info.Id
	button.Icon.Image = info.Image
	button.MouseButton1Click:Connect(function()
		print("Clicked")
		if isGamepass and not isOwned then
			-- Todo
		elseif not isGamepass and not isOwned then
			print("Clicked Subscription")
			MarketPlaceService:PromptSubscriptionPurchase(Player, info.Id)
		end
	end)

	Local.UpdateButton(info.Id, isOwned)
end

return Shared
