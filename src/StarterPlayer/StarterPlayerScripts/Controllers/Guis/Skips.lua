local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetStoreItemInfoRF = ReplicatedStorage:WaitForChild("GetStoreItemInfoRF")

local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)
local Remotes = ReplicatedStorage.Remotes

local Gui = GuiController.Guis.Skips
local OpenButton = GuiController.Guis.Top.Frame.Skip

local SKIP_BUTTON_TEXT = "REPLACE"

local Local = {}
local Shared = {}

function Shared.HideSkipButton()
	OpenButton.Visible = false
end

function Shared.ShowSkipButton()
	OpenButton.Visible = true
end

function Shared.OnStart()
	OpenButton.MouseButton1Click:Connect(function()
		local success, SkipsGamepass = pcall(function()
			return GetStoreItemInfoRF:InvokeServer("5 Skips")
		end)

		if not success then
			warn("Failed to get store data: ", SkipsGamepass)
			return
		end

		local skipAmount = StateController.GetState().skips.amount
		if skipAmount <= 0 then
			local productId = SkipsGamepass.Id
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
