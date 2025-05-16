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

-- Store original values when character loads
local originalValues = {
	WalkSpeed = nil,
	Gravity = nil,
	JumpHeight = nil,
}

function Shared.OnStart()
	Player.CharacterAdded:Connect(function(character)
		Local.SetupCharacter(Player)
	end)

	Local.SetupCharacter(Player)
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
		originalValues.JumpHeight = humanoid.JumpHeight
		originalValues.Gravity = Workspace.Gravity

		-- Update default values with original values
		COIL_EFFECTS.Default.WalkSpeed = originalValues.WalkSpeed
		COIL_EFFECTS.Default.JumpHeight = originalValues.JumpHeight
		COIL_EFFECTS.Default.Gravity = originalValues.Gravity
	end

	for _, tool in backpack:GetChildren() do
		Local.ApplyIconToTool(tool)
		Local.SetupCoil(tool)
	end

	backpack.ChildAdded:Connect(function(tool)
		Local.ApplyIconToTool(tool)
		Local.SetupCoil(tool)
	end)
end

function Local.SetupCoil(tool: Tool)
	tool.Equipped:Connect(function()
		Local.CoilEffect(tool.Name, true)
	end)

	tool.Unequipped:Connect(function()
		Local.CoilEffect(tool.Name, false)
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
	else
		humanoid.WalkSpeed = if didEquip then COIL_EFFECTS.Speed.WalkSpeed else COIL_EFFECTS.Default.WalkSpeed
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

return Shared
