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
		-- print("StateController - Remotes.SetData.OnClientEvent")
		State = playerData
	end)

	Remotes.UpdateData.OnClientEvent:Connect(function(action: UpdateState.UpdateStateAction)
		-- print("StateController - Remotes.UpdateData.OnClientEvent")
		if not State then
			print("StateController - Remotes.UpdateData.OnClientEvent - State is nil")
			return
		end

		-- print("StateController - Remotes.UpdateData.OnClientEvent - State is not nil")
		UpdateState(State, action)
		-- print("StateController - Remotes.UpdateData:Fire")
		Shared.UpdateState:Fire(action, State)
	end)

	-- print("StateController - Remotes.Start:FireServer")
	Remotes.Start:FireServer()
end

function Shared.GetState(): UpdateState.PlayerData
	while State == nil do
		task.wait(0.01)
	end

	return State
end

return Shared
