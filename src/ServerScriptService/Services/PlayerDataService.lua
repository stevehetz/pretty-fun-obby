local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
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
			Local.OnPlayerTeleport(player, data)
			Remotes.SetData:FireClient(player, data)
		end
	end)
	Players.PlayerAdded:Connect(Local.CreateProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)

	for _, player in Players:GetPlayers() do
		Local.CreateProfile(player)
	end
end

function Shared.GetState(player: Player)
	local profile = Profiles[player]
	if profile then
		-- profile.Data.skips.amount = 200
		return profile.Data
	end

	return nil
end

function Shared.UpdateState(player: Player, action: UpdateState.UpdateStateAction)
	local profile = Profiles[player]
	if not profile then
		return
	end

	if action.type == "UpdateStage" then
		player.leaderstats.Stage.Value += action.amount
	end

	if action.type == "UpdateFinishes" then
		player.leaderstats.Finishes.Value += action.amount
	end

	if action.type == "UpdateCurrentWorld" then
		local displayName = WorldsConfig.GetDisplayNameFromWorldName(action.world)
		player.leaderstats.CurrentWorld.Value = displayName or "World 1"
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

	local finishes = Instance.new("NumberValue", leaderstats)
	finishes.Name = "Finishes"
	finishes.Value = state.finishes

	local currentWorld = Instance.new("StringValue", leaderstats)
	currentWorld.Name = "CurrentWorld"
	local displayName = WorldsConfig.GetDisplayNameFromWorldName(state.currentWorld)
	currentWorld.Value = displayName or "World 1"
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

	Local.OnPlayerTeleport(player, profile.Data)
	Remotes.SetData:FireClient(player, profile.Data)
end

function Local.RemoveProfile(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
	end
end

function Local.OnPlayerTeleport(player: Player, state: DataTemplate.PlayerData)
	print("OnPlayerTeleport: ", player.Name)
	if state and state.teleporting.world then
		print("Teleporting player: ", player.Name, " to world: ", state.teleporting.world)
		local action = {
			type = "UpdateCurrentWorld",
			world = state.teleporting.world,
		}
		Shared.UpdateState(player, action)

		local action = {
			type = "UpdateTeleporting",
			world = nil,
		}
		Shared.UpdateState(player, action)

		if state.stage > 0 then
			local action = {
				type = "UpdateStage",
				amount = -state.stage,
			}
			Shared.UpdateState(player, action)
		end
	end
end

return Shared
