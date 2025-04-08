local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiController = require(script.Parent.Parent.Parent.GuiController)
local Remotes = ReplicatedStorage.Remotes

local RestartButton = GuiController.Guis.Top.Frame.Restart

local Shared = {}

function Shared.OnStart()
	RestartButton.MouseButton1Click:Connect(function()
		Remotes.PlayerData.Respawn:FireServer()
	end)
end

return Shared
