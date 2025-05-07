local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GetStoreRF = ReplicatedStorage:WaitForChild("GetStoreRF")

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
		local isGamepass = action.type == "UpdateGamepass"
		if isSubscription then
			-- ToDo
		elseif isGamepass then
			Local.UpdateButton(action.gamepassId, action.value)
		end
	end)
end

function Local.GenerateStore()
	local success, store = pcall(function()
		return GetStoreRF:InvokeServer()
	end)

	if not success then
		warn("Failed to get store data: ", store)
		return
	end

	for _, info in store.Gamepasses do
		Local.SetupButton(info, true)
	end

	-- for _, info in store.Subscriptions do
	-- 	Local.SetupButton(info, false)
	-- end
end

function Local.UpdateButton(id: string, isPurchased: boolean)
	local button: TextButton = Frame:FindFirstChild(id)

	if button then
		button.Visible = not isPurchased
	end
end

function Local.SetupButton(info, isGamepass: boolean?)
	local button: TextButton = Frame:FindFirstChild(info.Name:gsub(" ", ""))
	if not button then
		return
	end

	local state = StateController.GetState()
	local playerOwnsGamepass = state.gamepasses[tostring(info.Id)] or false
	local isOwned = if isGamepass then playerOwnsGamepass else state.vip

	button.Name = info.Id
	button.Icon.Image = info.Image
	button.MouseButton1Click:Connect(function()
		if isGamepass and not isOwned then
			MarketPlaceService:PromptGamePassPurchase(Player, info.Id)
		elseif not isGamepass and not isOwned then
			MarketPlaceService:PromptSubscriptionPurchase(Player, info.Id)
		end
	end)

	Local.UpdateButton(info.Id, isOwned)
end

return Shared
