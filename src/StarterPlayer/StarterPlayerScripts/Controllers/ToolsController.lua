local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StoreConfig = require(ReplicatedStorage.Configs.Store)

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
		WalkSpeed = 16,
		Gravity = 196.2,
		JumpHeight = 7.2,
	},
}

local Local = {}
local Shared = {}

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
	-- look up the info by name or Id, whichever you prefer
	local info = StoreConfig.GetStoreItemInfo(tool.Name)
	if info and info.Image then
		tool.TextureId = info.Image -- this is what the Backpack GUI uses
		tool.ToolTip = info.Name -- optional: hover-text
	end
end

return Shared
