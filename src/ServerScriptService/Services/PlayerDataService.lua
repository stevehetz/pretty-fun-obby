local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local ProfileService = require(ServerScriptService.Libs.ProfileService)
local WorldPortalService = require(ServerScriptService.Services.WorldPortalService)
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
		-- print("PlayerDataService - Remotes.Start:OnServerEvent")
		local data = Shared.GetState(player)

		-- When running in studio - data is there, but CreateProfile() has already sent it
		-- When running in client - data is nil so never fires, but CreateProfile() sends it anyway
		if data then
			-- print("PlayerDataService - Remotes.Start - HandleWorldTeleport")
			-- Local.HandleWorldTeleport(player, data)

			-- When this fires, nothing happens because the controller only handles it once
			-- And it's already being fired int he create profile which happens first
			-- Not sure why it's here, I guess just incase the data wasn't ready first time
			-- print("PlayerDataService - Remotes.SetData:FireClient")
			Remotes.SetData:FireClient(player, data)
		end
	end)

	-- This is used when I run the game in roblox client
	Players.PlayerAdded:Connect(function(player: Player)
		-- print("PlayerDataService - PlayerAdded:Connect")
		Local.CreateProfile(player)
	end)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)

	-- This is used when I run the game in roblox studio
	for _, player in Players:GetPlayers() do
		-- print("PlayerDataService - Players:GetPlayers")
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
	-- print("PlayerDataService - UpdateData - FireClient")
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
	-- print("PlayerDataService - CreateProfile")
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

	if RunService:IsStudio() then
		-- print("PlayerDataService - In Roblox Studio, do not setup WorldPortalService")

		-- print("PlayerDataService - CreateProfile - ProfileLoaded:Fire")
		Shared.ProfileLoaded:Fire(player)
		-- print("PlayerDataService - CreateProfile - Remotes.SetData:FireClient")
		Remotes.SetData:FireClient(player, profile.Data)
	end

	-- New

	-- Run this if not in roblox studio
	if not RunService:IsStudio() then
		-- print("PlayerDataService - In Roblox Studio, do not setup WorldPortalService")

		-- Old
		-- -- print("PlayerDataService - CreateProfile - ProfileLoaded:Fire")
		-- Shared.ProfileLoaded:Fire(player)
		-- -- print("PlayerDataService - CreateProfile - Remotes.SetData:FireClient")
		-- Remotes.SetData:FireClient(player, profile.Data)

		-- New
		print("PlayerDataService - In Roblox Client, setup WorldPortalService")
		WorldPortalService.HandleWorldTeleportComplete.Event:Connect(function()
			-- print("PlayerDataService - HandleWorldTeleportComplete:Connect")

			-- print("PlayerDataService - ProfileLoaded:Fire")
			Shared.ProfileLoaded:Fire(player)

			-- print("PlayerDataService - Remotes.SetData:FireClient")
			Remotes.SetData:FireClient(player, profile.Data)

			WorldPortalService.SetupPortals(profile.Data)
		end)

		WorldPortalService.HandleWorldTeleport(player, profile.Data)
	end
end

function Local.RemoveProfile(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
	end
end

return Shared
