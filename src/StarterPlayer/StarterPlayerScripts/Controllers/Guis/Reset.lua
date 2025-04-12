local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local SoundsConfig = require(ReplicatedStorage.Configs.Sounds)
local GuiController = require(script.Parent.Parent.GuiController)
local RespawnController = require(script.Parent.Parent.RespawnController)

local Gui = GuiController.Guis.Top
local Button = Gui.Frame.Reset

local BUTTON_TEXT = "Reset (REPLACE)"

local Local = {}
local Shared = {}

function Shared.OnStart()
	Button.MouseButton1Click:Connect(Local.Reset)
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end

		local isResetButton = input.KeyCode == Enum.KeyCode.ButtonY or input.KeyCode == Enum.KeyCode.R
		if isResetButton then
			Local.Reset()
		end
	end)

	UserInputService.LastInputTypeChanged:Connect(function(lastInputType: Enum.UserInputType)
		local isMouseKeyboard = lastInputType == Enum.UserInputType.MouseButton1
			or lastInputType == Enum.UserInputType.Keyboard
		local isGamePad = lastInputType == Enum.UserInputType.Gamepad1

		if isMouseKeyboard then
			Button.Title.Text = BUTTON_TEXT:gsub("REPLACE", "R")
		elseif isGamePad then
			Button.Title.Text = BUTTON_TEXT:gsub("REPLACE", "Y")
		end
	end)
end

function Local.Reset()
	local character = Player.Character
	if character then
		RespawnController.RespawnPlayer(character, true)
		SoundsConfig.PlaySound("Error")
	end
end

return Shared
