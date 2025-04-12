local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local StateController = require(script.Parent.StateController)
local Remotes = ReplicatedStorage.Remotes

local CHAT_PREFIX_STRING = `<font color="rgb(255, 255, 0)">[VIP 👑]</font>`
local VipPlayers = {}

local Local = {}
local Shared = {}

function Shared.OnStart()
	TextChatService.OnIncomingMessage = Local.UpdateMessage
	
	Remotes.UpdateVip.OnClientEvent:Connect(Local.UpdateVip)
	Players.PlayerRemoving:Connect(Local.UpdateVip)

	local isVip = StateController.GetState().vip
	Local.UpdateVip(Players.LocalPlayer, isVip)
end

function Local.UpdateVip(player: Player, isSubscribed: boolean?)
	if isSubscribed then
		table.insert(VipPlayers, player.UserId)
	else
		local index = table.find(VipPlayers, player.UserId)
		if index then
			table.remove(VipPlayers, index)
		end
	end
end

function Local.UpdateMessage(message: TextChatMessage)
	local messageProps = Instance.new("TextChatMessageProperties")

	local source = message.TextSource
	if source then
		local userId = source.UserId
		local isVip = table.find(VipPlayers, userId)
		if isVip then
			messageProps.PrefixText = `{CHAT_PREFIX_STRING} {messageProps.PrefixText}`
		end
	end

	return messageProps
end

return Shared
