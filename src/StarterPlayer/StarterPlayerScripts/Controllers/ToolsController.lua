local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetStoreItemInfoRF = ReplicatedStorage:WaitForChild("GetStoreItemInfoRF")

local Player = Players.LocalPlayer

type Coil = "Gravity Coil" | "Speed Coil"

local COIL_EFFECTS = {
	Speed = {
		WalkSpeed = 50,
	},
	Gravity = {
		Gravity = 100,
		JumpHeight = 50,
	},
	Default = {
		WalkSpeed = nil, -- Will be set to player's original value
		Gravity = nil, -- Will be set to workspace's original value
		JumpHeight = nil, -- Will be set to player's original value
	},
}

local Local = {}
local Shared = {}

Local.ToolsSetup = {
	["Gravity Coil"] = false,
	["Speed Coil"] = false,
	["Trashcan"] = false,
	["Sword"] = false,
}

Shared.ToolToggled = Instance.new("BindableEvent")

-- Store original values when character loads
local originalValues = {
	WalkSpeed = nil,
	Gravity = nil,
	JumpHeight = nil,
}

function Local.ResetToolsSetup()
	for toolName, _ in pairs(Local.ToolsSetup) do
		Local.ToolsSetup[toolName] = false
	end
end

function Shared.OnStart()
	Player.CharacterAdded:Connect(function()
		Local.ResetToolsSetup()
		Local.SetupCharacter(Player)
	end)

	Local.SetupCharacter(Player)
end

function Shared.IsToolEquipped(toolName: string): boolean
	local character = Player.Character or Player.CharacterAdded:Wait()
	return character:FindFirstChild(toolName) ~= nil
end

function Shared.ToggleEquip(toolName: string)
	local character = Player.Character or Player.CharacterAdded:Wait()
	-- Check if tools is already equipped
	local isEquipped = character:FindFirstChild(toolName)
	if isEquipped then
		-- If tool is already equipped, unequip it
		character.Humanoid:UnequipTools()
		return
	else
		local backpack = Player.Backpack or Player:WaitForChild("Backpack")
		local tool = backpack:FindFirstChild(toolName)

		if not tool then
			warn("Tool not found in backpack: ", toolName)
			return
		end
		tool.Parent = character
		character.Humanoid:EquipTool(tool)
	end
end

function Local.SetupCharacter(player: Player)
	local character = player.Character or Player.CharacterAdded:Wait()
	local backpack = player.Backpack or player:WaitForChild("Backpack")
	if not character or not backpack then
		return
	end

	-- Store original values when character loads
	local humanoid = character:WaitForChild("Humanoid")
	if humanoid then
		originalValues.WalkSpeed = humanoid.WalkSpeed
		-- Adding 2 to JumpHeight fixes weird bug where jump height is effected by changing walk speed
		originalValues.JumpHeight = humanoid.JumpHeight + 2
		originalValues.Gravity = Workspace.Gravity

		-- Update default values with original values
		COIL_EFFECTS.Default.WalkSpeed = originalValues.WalkSpeed
		COIL_EFFECTS.Default.JumpHeight = originalValues.JumpHeight
		COIL_EFFECTS.Default.Gravity = originalValues.Gravity
	end

	-- Setup tools should run when player joins or after respawn

	-- This runs when character dies and respawns
	for _, tool in backpack:GetChildren() do
		Local.SetupTools(tool)
	end

	-- This runs when player joins game or when tool is equipped first time or requipped
	-- We don't want setuptools to run when unequipping a tool
	backpack.ChildAdded:Connect(function(tool)
		Local.SetupTools(tool)
	end)
end

function Local.SetupTools(tool)
	if Local.ToolsSetup[tool.Name] then
		return
	end

	Local.ToolsSetup[tool.Name] = true

	if tool.Name == "Gravity Coil" or tool.Name == "Speed Coil" then
		Local.ApplyIconToTool(tool)
	end

	if tool.Name == "Trashcan" then
		Local.SetupTrashcan(tool)
	end

	if tool.Name == "Sword" then
		Local.SetupSword(tool)
	end

	tool.Equipped:Connect(function()
		Shared.ToolToggled:Fire(tool.Name)
		if tool.Name == "Gravity Coil" or tool.Name == "Speed Coil" then
			Local.CoilEffect(tool.Name, true)
		end
	end)

	tool.Unequipped:Connect(function()
		Shared.ToolToggled:Fire(tool.Name)
		if tool.Name == "Gravity Coil" or tool.Name == "Speed Coil" then
			Local.CoilEffect(tool.Name, false)
		end
	end)
end

function Local.CoilEffect(coil: Coil, didEquip: boolean)
	local humanoid: Humanoid = Player.Character:WaitForChild("Humanoid")
	if not humanoid then
		return
	end

	if coil == "Gravity Coil" then
		humanoid.JumpHeight = if didEquip then COIL_EFFECTS.Gravity.JumpHeight else COIL_EFFECTS.Default.JumpHeight
		Workspace.Gravity = if didEquip then COIL_EFFECTS.Gravity.Gravity else COIL_EFFECTS.Default.Gravity
	elseif coil == "Speed Coil" then
		humanoid.WalkSpeed = if didEquip then COIL_EFFECTS.Speed.WalkSpeed else COIL_EFFECTS.Default.WalkSpeed
		humanoid.JumpHeight = COIL_EFFECTS.Default.JumpHeight
	end
end

function Local.ApplyIconToTool(tool)
	local success, info = pcall(function()
		return GetStoreItemInfoRF:InvokeServer(tool.Name)
	end)

	if not success then
		warn("Failed to get store data: ", info)
		return
	end

	if info and info.Image then
		tool.TextureId = info.Image
		tool.ToolTip = tool.Name
	end
end

function Local.SetupTrashcan(tool)
	local animsFolder = tool.Animations
	local isEquipped = false

	tool.TextureId = "rbxassetid://124631666409554"

	local player = game.Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")

	local db = 0

	local animsTable = {
		["Equip"] = hum:LoadAnimation(animsFolder.Equip),
		["Idle"] = hum:LoadAnimation(animsFolder.Idle),
		["Throw"] = hum:LoadAnimation(animsFolder.Throw),
	}

	tool.Activated:Connect(function()
		if db == 0 then
			db = 1
			animsTable.Idle:Stop()
			animsTable.Throw:Play()

			task.wait(0.3)

			animsTable.Throw:Stop()
			animsTable.Idle:Play()

			task.wait(1)

			db = 0
		end
	end)

	tool.Equipped:Connect(function()
		isEquipped = true
		animsTable.Equip:Play()
	end)

	animsTable.Equip.Stopped:Connect(function()
		if not isEquipped then
			return
		end
		animsTable.Idle:Play()
	end)

	tool.Unequipped:Connect(function()
		isEquipped = false
		animsTable.Equip:Stop()
		animsTable.Idle:Stop()
		animsTable.Throw:Stop()
	end)
end

function Local.SetupSword(tool)
	local animsFolder = tool.Animations

	tool.TextureId = "rbxassetid://72423564181069"
	-- tool.TextureId = "rbxassetid://132297503323667"
	-- tool.TextureId = "rbxassetid://125949931514022"
	-- tool.TextureId = "rbxassetid://86699930350799"

	local player = game.Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")

	local db = 0

	local animsTable = {
		["Slash"] = hum:LoadAnimation(animsFolder.Slash),
		["Idle"] = hum:LoadAnimation(animsFolder.Idle),
	}

	tool.Activated:Connect(function()
		if db == 0 then
			db = 1
			animsTable.Idle:Stop()
			animsTable.Slash:Play()

			task.wait(0.3)

			animsTable.Slash:Stop()
			animsTable.Idle:Play()

			db = 0
		end
	end)

	tool.Unequipped:Connect(function()
		animsTable.Slash:Stop()
		animsTable.Idle:Stop()
	end)
end

return Shared
