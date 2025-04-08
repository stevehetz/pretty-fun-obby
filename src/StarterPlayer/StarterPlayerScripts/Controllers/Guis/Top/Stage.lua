local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

local GuiController = require(script.Parent.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.Parent.StateController)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)

local Gui = GuiController.Guis.Top
local ProgressBar = Gui.Frame.Stage

local STAGE_TEXT = "Stage AMOUNT (PERCENT%)"

local Local = {}
local Shared = {}

function Shared.OnStart()
	Local.UpdateProgress()
	
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		if action.type == "UpdateStage" or action.type == "RestartGame" then
			Local.UpdateProgress()
		end
	end)
end

function Local.UpdateProgress()
	local currentStage = StateController.GetState().stage
	local totalStages = StagesConfig.GetTotalStages()
	local progressPercent = currentStage / totalStages
	
	local progressText = STAGE_TEXT:gsub("AMOUNT", currentStage)
	progressText = progressText:gsub("PERCENT", math.floor(progressPercent * 100))
	GuiController.HandleProgressBar(ProgressBar, progressPercent, progressText)
end


return Shared