local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)
local PlayerDataService = require(script.Parent.PlayerDataService)
local CoinService = require(script.Parent.CoinService)
local ToolsService = require(script.Parent.ToolsService)
local StoreConfig = require(ServerStorage.Configs.Store)

local Local = {}
local Shared = {}

-- Table to track debounce states for each player and display
local TouchDebounce = {}

function Shared.OnStart()
	PlayerDataService.ProfileLoaded.Event:Connect(function(player: Player)
		local state: PlayerData.PlayerData = PlayerDataService.GetState(player)

		if not state then
			return
		end
		Local.SetupDisplays(player, state)
	end)
end

function Local.SetupDisplays(player: Player, state: PlayerData.PlayerData)
	local ItemDisplaysFolder = Workspace:WaitForChild("ItemDisplays")

	if ItemDisplaysFolder then
		for _, itemDisplay in ipairs(ItemDisplaysFolder:GetChildren()) do
			-- Setup display content
			Local.SetupDisplay(player, state, itemDisplay)

			-- Set up touch event for each child
			local touchPart = itemDisplay:FindFirstChild("Disc")
			if touchPart then
				Local.SetupDisplayTouch(player, state, touchPart)
			end
		end
	end
end

function Local.SetupDisplay(player: Player, state: PlayerData.PlayerData, display: Instance)
	local storeItemInfo = StoreConfig.GetStoreItemInfo(display.Name)
	if storeItemInfo and storeItemInfo.IsGamepass then
		local namePlate = display.NamePlate

		-- Set name on name plate
		local nameLabel = namePlate.SurfaceGui.Frame.NameLabel
		nameLabel.Text = display.Name

		-- Set price on name plate
		local priceLabel = namePlate.SurfaceGui.Frame.PriceFrame.Price
		priceLabel.Text = storeItemInfo.Price
	end
end

function Local.SetupDisplayTouch(player: Player, state: PlayerData.PlayerData, touchPart: Part)
	if touchPart:IsA("BasePart") then
		touchPart.Touched:Connect(function(hit)
			local character = hit.Parent
			local touchedPlayer = game.Players:GetPlayerFromCharacter(character)

			if touchedPlayer and touchedPlayer == player then
				-- Create a unique key for this player-display combination
				local debounceKey = player.UserId .. "_" .. touchPart:GetFullName()

				-- Check if this combination is currently in debounce
				if not TouchDebounce[debounceKey] then
					-- Set debounce to true
					TouchDebounce[debounceKey] = true

					-- Call the touch function
					local display = touchPart.Parent
					Local.OnDisplayTouched(player, state, display)

					-- Reset debounce after 1 second
					task.delay(1, function()
						TouchDebounce[debounceKey] = nil
					end)
				end
			end
		end)
	end
end

function Local.OnDisplayTouched(player: Player, state: PlayerData.PlayerData, display: Instance)
	-- Is a gamepass
	local storeItemInfo = StoreConfig.GetStoreItemInfo(display.Name)
	if storeItemInfo and storeItemInfo.IsGamepass then
		-- If not owns gamepass, prompt purchase
		if not state.gamepasses[tostring(storeItemInfo.Id)] then
			Local.TryPurchaseGamepass(player, storeItemInfo.Id)
		end

		return
	end

	-- Is a coin store item
	local coinStoreItemInfo = CoinService.GetCoinStoreItemInfo(display.Name)
	if coinStoreItemInfo then
		Local.TryPurchaseCoinStoreItem(player, state, display.Name)
		return
	end
end

function Local.TryPurchaseGamepass(player: Player, gamepassId: number)
	local success, errorMessage = pcall(function()
		game:GetService("MarketplaceService"):PromptGamePassPurchase(player, gamepassId)
	end)

	if not success then
		warn("Failed to prompt gamepass purchase:", errorMessage)
	end
end

function Local.TryPurchaseCoinStoreItem(player: Player, state, itemName: string)
	if itemName == "Trashcan" and state.hasTrashcan then
		warn("Player already has a trashcan.")
		return
	end

	local success, errorMessage = pcall(function()
		local purchased = CoinService.Purchase(player, itemName)

		if purchased then
			ToolsService.EquipTool(player, itemName)
		end
	end)

	if not success then
		warn("Failed to purchase coin store item:", errorMessage)
		return
	end
end

return Shared
