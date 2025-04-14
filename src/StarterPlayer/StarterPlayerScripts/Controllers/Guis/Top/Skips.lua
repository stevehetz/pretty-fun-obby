local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StoreConfig = require(ReplicatedStorage.Configs.Store)
local GuiController = require(script.Parent.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.Parent.StateController)
local Remotes = ReplicatedStorage.Remotes

local Gui = GuiController.Guis.Skips
local OpenButton = GuiController.Guis.Top.Frame.Skip

local SKIP_BUTTON_TEXT = "REPLACE"

local Local = {}
local Shared = {}

function Shared.OnStart()
	OpenButton.MouseButton1Click:Connect(function()
		local skipAmount = StateController.GetState().skips.amount
		if skipAmount <= 0 then
			local productId = StoreConfig.GetStoreItemInfo("5 Skips").Id
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
			return
		end

		Remotes.Skip:FireServer()
	end)

	Local.UpdateSkipButton()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		local isEarnedSkip = action.type == "EarnSkip"
		local isUseSkip = action.type == "UseSkip"

		if isEarnedSkip or isUseSkip then
			Local.UpdateSkipButton()
		end
	end)
end

function Local.UpdateSkipButton()
	local skipAmount = StateController.GetState().skips.amount
	local skipText = SKIP_BUTTON_TEXT:gsub("REPLACE", skipAmount > 0 and "Skip (" .. skipAmount .. ")" or "Skip")
	OpenButton.Title.Text = skipText
end

return Shared
