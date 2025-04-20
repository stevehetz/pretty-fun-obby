local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpdateState = require(ReplicatedStorage.Functions.UpdateState)
local Remotes = ReplicatedStorage.Remotes.PlayerData

export type UpdateStateAction = UpdateState.UpdateStateAction
export type PlayerData = UpdateState.PlayerData

local State: UpdateState.PlayerData

local Local = {}
local Shared = {}

Shared.UpdateState = Instance.new("BindableEvent")

function Shared.OnStart()
	Remotes.SetData.OnClientEvent:Once(function(playerData: UpdateState.PlayerData)
		State = playerData
	end)

	Remotes.UpdateData.OnClientEvent:Connect(function(action: UpdateState.UpdateStateAction)
		print("UpdateData: ", action.type)
		if not State then
			return
		end

		UpdateState(State, action)
		Shared.UpdateState:Fire(action, State)
	end)

	Remotes.Start:FireServer()
end

function Shared.GetState(): UpdateState.PlayerData
	while State == nil do
		task.wait(0.01)
	end

	return State
end

return Shared
