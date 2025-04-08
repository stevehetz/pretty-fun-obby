local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileService = require(ServerScriptService.Libs.ProfileService)
local DataTemplate = require(ReplicatedStorage.PlayerData)
local UpdateState = require(ReplicatedStorage.Functions.UpdateState)
local Remotes = ReplicatedStorage.Remotes.PlayerData

export type UpdateStateAction = UpdateState.UpdateStateAction

local DATASTORE_NAME = "Production" -- DO NOT MODIFY

if RunService:IsStudio() then
	DATASTORE_NAME = "Testing"
end

local ProfileStore = ProfileService.GetProfileStore(DATASTORE_NAME, DataTemplate.DEFAULT_PLAYER_DATA)

local Profiles: { [Player]: ProfileService.Profile<DataTemplate.PlayerData> } = {}

local Local = {}
local Shared = {}

Shared.ProfileLoaded = Instance.new("BindableEvent")

function Shared.OnStart()
	Remotes.Start.OnServerEvent:Connect(function(player: Player)
		local data = Shared.GetState(player)
		if data then
			Remotes.SetData:FireClient(player, data)
		end
	end)
	Remotes.Restart.OnServerEvent:Connect(function(player: Player)
		print("restart called")
		local action: UpdateStateAction = {
			type = "RestartGame",
			value = true
		}
		Shared.UpdateState(player, action)
	end)
	Players.PlayerAdded:Connect(Local.CreateProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfiile)
	
	for _, player in Players:GetPlayers() do
		Local.CreateProfile(player)
	end
end

function Shared.GetState(player: Player)
	local profile = Profiles[player]
	if profile then
		return profile.Data
	end
	
	return nil
end

function Shared.UpdateState(player: Player, action: UpdateState.UpdateStateAction)
	local profile = Profiles[player]
	if not profile then return end
	
	if action.type == "RestartGame" then
		player.leaderstats.Stage.Value = 1
		player.leaderstats.Deaths.Value = 0
	elseif action.type == "UpdateStage" then
		player.leaderstats.Stage.Value += action.amount
	elseif action.type == "UpdateDeaths" then
		player.leaderstats.Deaths.Value += action.amount
	end
	
	
	
	
	UpdateState(profile.Data, action)
	Remotes.UpdateData:FireClient(player, action)
end

function Local.CreateLeaderstats(player: Player)
	local state = Shared.GetState(player)
	if not state then
		return
	end
	
	local leaderstats = Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"
	
	local stage = Instance.new("NumberValue", leaderstats)
	stage.Name = "Stage"
	stage.Value = state.stage
	
	local death = Instance.new("NumberValue", leaderstats)
	death.Name = "Deaths"
	death.Value = state.deaths
end

function Local.CreateProfile(player: Player)
	local userId = player.UserId
	local profileKey = `{userId}_Data`
	local profile = ProfileStore:LoadProfileAsync(profileKey)
	
	if not profile then
		player:Kick("Unable to load your player data.")
		return
	end
	
	profile:ListenToRelease(function()
		Profiles[player] = nil
		player:Kick()
	end)
	
	profile:AddUserId(userId)
	profile:Reconcile()
	
	Profiles[player] = profile
	Local.CreateLeaderstats(player)
	Shared.ProfileLoaded:Fire(player)
	
	Remotes.SetData:FireClient(player, profile.Data)
end

function Local.RemoveProfiile(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
	end
end

return Shared