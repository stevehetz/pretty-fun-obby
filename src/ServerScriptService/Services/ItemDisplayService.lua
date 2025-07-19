local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require(ReplicatedStorage.PlayerData)
local PlayerDataService = require(script.Parent.PlayerDataService)
local CoinService = require(script.Parent.CoinService)
local ToolsService = require(script.Parent.ToolsService)
local PetService = require(script.Parent.PetService)
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
		nameLabel.Text = storeItemInfo.Name

		-- Set price on name plate
		local priceLabel = namePlate.SurfaceGui.Frame.PriceFrame.Price
		if storeItemInfo.Price == 0 then
			priceLabel.Text = "Free"
		else
			priceLabel.Text = storeItemInfo.Price
		end
	end

	local coinStoreItemInfo = CoinService.GetCoinStoreItemInfo(display.Name)
	if coinStoreItemInfo then
		local namePlate = display.NamePlate

		-- Set name on name plate
		local nameLabel = namePlate.SurfaceGui.Frame.NameLabel
		nameLabel.Text = coinStoreItemInfo.DisplayName or coinStoreItemInfo.Name

		-- Set price on name plate
		local priceLabel = namePlate.SurfaceGui.Frame.PriceFrame.Price
		local coinIcon = namePlate.SurfaceGui.Frame.PriceFrame:FindFirstChild("CoinIcon")
		if coinStoreItemInfo.Value == 0 then
			if coinIcon then
				coinIcon.Visible = false
			end
			priceLabel.Text = "FREE"
			priceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		else
			if coinIcon then
				coinIcon.Visible = true
			end
			priceLabel.Text = coinStoreItemInfo.Value
			priceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
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
		print("Display touched for gamepass:", storeItemInfo.Name)
		-- If not owns gamepass, prompt purchase
		if not state.gamepasses[tostring(storeItemInfo.Id)] then
			Local.TryPurchaseGamepass(player, storeItemInfo.Id)
			return
		end

		-- Player already owns the gamepass
		if storeItemInfo.IsTool then
			-- If it's a tool, try to equip it
			Local.TryEquipOwnedTool(player, storeItemInfo.Name)
		elseif storeItemInfo.IsPet then
			-- If it's a pet, try to equip it
			Local.TryEquipPet(player, storeItemInfo.Name)
		end

		return
	end

	-- Is a coin store item
	local coinStoreItemInfo = CoinService.GetCoinStoreItemInfo(display.Name)
	if coinStoreItemInfo then
		-- Check if player already owns the item
		if Local.PlayerOwnsItem(player, state, display.Name) then
			-- Player already owns the item, try to equip it
			Local.TryEquipOwnedTool(player, display.Name)
		else
			-- Player doesn't own the item, try to purchase it
			Local.TryPurchaseCoinStoreItem(player, state, display.Name)
		end
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

-- Check if player already owns an item
function Local.PlayerOwnsItem(player: Player, state: PlayerData.PlayerData, itemName: string)
	-- Check specific state properties for known items
	if itemName == "Trashcan" and state.hasTrashcan then
		return true
	end

	if itemName == "Sword" and state.hasSword then
		return true
	end

	-- Check if item is in backpack or equipped
	local backpack = player.Backpack
	if backpack and backpack:FindFirstChild(itemName) then
		return true
	end

	local character = player.Character
	if character and character:FindFirstChild(itemName) then
		return true
	end

	return false
end

-- Try to equip a tool that the player already owns
function Local.TryEquipOwnedTool(player: Player, toolName: string)
	local character = player.Character
	if not character then
		return false
	end

	-- If tool is already equipped, do nothing
	if character:FindFirstChild(toolName) then
		print("Tool already equipped:", toolName)
		return true
	end

	-- Check if tool is in backpack
	local backpack = player.Backpack
	if not backpack then
		return false
	end

	local tool = backpack:FindFirstChild(toolName)
	if not tool then
		-- Tool not found in backpack, might need to give it first
		if ReplicatedStorage.Tools:FindFirstChild(toolName) then
			ToolsService.GiveTool(player, toolName)
			task.wait(0.1) -- Wait a bit for the tool to be added to backpack
			tool = backpack:FindFirstChild(toolName)
		end

		if not tool then
			print("Tool not found in backpack:", toolName)
			return false
		end
	end

	-- Equip the tool
	ToolsService.EquipTool(player, toolName)
	print("Equipped tool:", toolName)
	return true
end

-- Try to equip a pet
function Local.TryEquipPet(player: Player, petName: string)
	-- Create a pet object with the name
	local pet = {
		Name = petName,
	}

	-- Check if pet is already equipped
	local state = PlayerDataService.GetState(player)
	if not state then
		return false
	end

	-- If pet is already equipped, do nothing
	if state.equippedPets[petName] then
		print("Pet already equipped:", petName)
		return true
	end

	-- Equip the pet
	PetService.UpdateEquippedPets(player, pet)
	print("Equipped pet:", petName)
	return true
end

return Shared
