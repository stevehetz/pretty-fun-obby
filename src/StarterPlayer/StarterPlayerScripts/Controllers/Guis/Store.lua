local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GetStoreRF = ReplicatedStorage:WaitForChild("GetStoreRF")
local GetStoreItemInfoRF = ReplicatedStorage:WaitForChild("GetStoreItemInfoRF")

local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)
local DoubleJumpController = require(script.Parent.Parent.DoubleJumpController)

local Gui = GuiController.Guis.Left
local Frame = Gui.Frame

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.GenerateStore()

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		local isSubscription = action.type == "UpdateVip"
		local isGamepass = action.type == "UpdateGamepass"
		local isDoubleJumpToggle = action.type == "UpdateDoubleJump"

		if isSubscription then
			-- ToDo
		elseif isGamepass then
			local infoSuccess, gamepassInfo = pcall(function()
				return GetStoreItemInfoRF:InvokeServer(action.gamepassId)
			end)

			if infoSuccess and gamepassInfo and gamepassInfo.Name then
				if gamepassInfo.Name == "Double Jump" then
					Local.SetupButton(gamepassInfo, true)
				else
					Local.UpdateButton(gamepassInfo.Name, action.value)
				end
			else
				warn("Failed to get gamepass info for ID:", action.gamepassId)
			end
		elseif isDoubleJumpToggle then
			Local.UpdateDoubleJumpButton(not action.value)
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

function Local.UpdateButton(name: string, isPurchased: boolean)
	local button: TextButton = Frame:FindFirstChild(name:gsub(" ", ""))

	if button then
		button.Visible = not isPurchased
	end
end

function Local.SetupButton(info, isGamepass: boolean?)
	if not info or not info.Name then
		return
	end

	local button: TextButton = Frame:FindFirstChild(info.Name:gsub(" ", ""))
	if not button then
		return
	end

	local state = StateController.GetState()
	local playerOwnsGamepass = state.gamepasses[tostring(info.Id)] or false
	local isOwned = if isGamepass then playerOwnsGamepass else state.vip

	-- button.Name = info.Id
	button.Icon.Image = info.Image

	-- Special handling for Double Jump gamepass (ID: 1160545563)
	if info.Name == "Double Jump" and isGamepass then
		print("here")
		button.MouseButton1Click:Connect(function()
			if not isOwned then
				MarketPlaceService:PromptGamePassPurchase(Player, info.Id)
			else
				-- Toggle double jump functionality
				print("Toggling double jump")
				DoubleJumpController.Toggle()
			end
		end)

		print("disableDoubleJump: ", state.disableDoubleJump)

		-- Initialize button appearance based on current state
		Local.UpdateDoubleJumpButton(not state.disableDoubleJump)
	else
		button.MouseButton1Click:Connect(function()
			if isGamepass and not isOwned then
				MarketPlaceService:PromptGamePassPurchase(Player, info.Id)
			elseif not isGamepass and not isOwned then
				MarketPlaceService:PromptSubscriptionPurchase(Player, info.Id)
			end
		end)

		Local.UpdateButton(info.Name, isOwned)
	end
end

-- Update the Double Jump button appearance based on enabled/disabled state
function Local.UpdateDoubleJumpButton(isEnabled)
	local state = StateController.GetState()
	if not state then
		return
	end

	local playerOwnsGamepass = state.gamepasses[tostring(1226559308)] or false
	isEnabled = isEnabled and playerOwnsGamepass

	local doubleJumpButton = Frame:FindFirstChild("DoubleJump")
	if doubleJumpButton then
		local title = doubleJumpButton:FindFirstChild("Title")
		local status = doubleJumpButton:FindFirstChild("Status")
		if title then
			title.TextColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
		end
		if status then
			status.TextColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
			status.Text = isEnabled and "On" or "Off"
		end
	end
end

return Shared
