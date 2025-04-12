local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local SoundsConfig = require(ReplicatedStorage.Configs.Sounds)
local GuiController = require(script.Parent.Parent.GuiController)
local StateController = require(script.Parent.Parent.StateController)
local Remotes = ReplicatedStorage.Remotes

local Gui = GuiController.Guis.Rebirth
local Frame = Gui.Frame
local ProgressBar = Frame.ProgressBar
local UseButton = Frame.Use
local OpenButton = GuiController.Guis.Top.Frame.Rebirth

local Local = {}
local Shared = {}

function Shared.OnStart()
	GuiController.SetupGui(Gui, OpenButton)
	Local.UpdateProgress()
	
	UseButton.MouseButton1Click:Connect(function()
		GuiController.ToggleGui(Gui, false)
		Local.Rebirth()
	end)

	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction, newState: StateController.PlayerData)
		local isStage = action.type == "UpdateStage"
		local isRebirth = action.type == "Rebirth"
		if isStage or isRebirth then
			Local.UpdateProgress()
		end

		
		if isStage then
			local newStage = newState.stage
			local canRebirth = newStage >= StagesConfig.GetTotalStages()
			if canRebirth then
				GuiController.ToggleGui(Gui)
			end
		end
	end)

end

function Local.UpdateProgress()
	local stage = StateController.GetState().stage
	local totalStages = StagesConfig.GetTotalStages()
	local progress = stage / totalStages
	local progressText = string.format(`{stage}/{totalStages}`)
	GuiController.HandleProgressBar(ProgressBar, progress, progressText)
end

function Local.Rebirth()
	local stage = StateController.GetState().stage
	local totalStages = StagesConfig.GetTotalStages()
	-- local canRebirth = stage >= totalStages
	local canRebirth = true
	if canRebirth then
		Remotes.Rebirth:FireServer()
		-- SoundsConfig.PlaySound("Rebirth")
	else
		SoundsConfig.PlaySound("Error")
	end
end

return Shared
