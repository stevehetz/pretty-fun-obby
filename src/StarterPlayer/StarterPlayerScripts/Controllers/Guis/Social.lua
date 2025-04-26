local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Player = Players.LocalPlayer

local GuiController = require(script.Parent.Parent.GuiController)
local SoundsConfig = require(ReplicatedStorage.Configs.Sounds)

local Gui = GuiController.Guis.Top
local Button = Gui.Frame.Social

local InviteOptions = Instance.new("ExperienceInviteOptions")
InviteOptions.PromptMessage = "Challenge friends to beat your stage!"
InviteOptions.InviteMessageId = "32d8cd76-0df3-1f44-a191-5f4f215ea47a"

local Local = {}
local Shared = {}

function Shared.OnStart()
	local canSendInvite = Local.CanSendInvite()
	Button.Visible = canSendInvite

	Button.MouseButton1Click:Connect(function()
		local success, error = pcall(function()
			return SocialService:PromptGameInvite(Player, InviteOptions)
		end)

		if success then
			SoundsConfig.PlaySound("Confirm")
		else
			SoundsConfig.PlaySound("Error")
		end
	end)
end

function Local.CanSendInvite()
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(Player)
	end)

	return success and canSend
end

return Shared
