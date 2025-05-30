local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local PlayerData = require(ReplicatedStorage.PlayerData)
local GlobalDataService = require(ServerScriptService.Services.GlobalDataService)
local WorldsConfig = require(ReplicatedStorage.Configs.Worlds)
local StagesConfig = require(ReplicatedStorage.Configs.Stages)
local TestConfig = require(ReplicatedStorage.Configs.Test)
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

Local.TeleportEventInitialized = false

Shared.ProfileLoaded = Instance.new("BindableEvent")

function Shared.OnStart()
	WorldPortalService.SetupPortals(Profiles)

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

			-- Create a deep copy of the data to avoid cyclic references
			local clientData = table.clone(data)
			Remotes.SetData:FireClient(player, clientData)
		end
	end)

	-- if not roblox studio
	if not RunService:IsStudio() then
		WorldPortalService.HandleWorldTeleportComplete.Event:Connect(
			function(player: Player, state: PlayerData.PlayerData)
				print("PlayerDataService - HandleWorldTeleportComplete.Event:Connect")

				-- print("PlayerDataService - HandleWorldTeleportComplete:Connect")

				-- print("PlayerDataService - ProfileLoaded:Fire")
				Shared.ProfileLoaded:Fire(player)

				-- print("PlayerDataService - Remotes.SetData:FireClient")

				-- Create a deep copy of the state to avoid cyclic references
				local clientState = table.clone(state)
				Remotes.SetData:FireClient(player, clientState)
			end
		)
	end

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
		return profile.Data
	end

	return nil
end

function Local.InitState(player: Player)
	local profile = Profiles[player]
	local state = profile.Data

	-- local totalStages = StagesConfig.GetTotalStages()

	-- if totalStages < 0 or state.stage > totalStages then
	-- 	state.stage = 0
	-- end

	-- Player always starts at stage 0
	state.stage = 0

	-- state.oneTimePass = false -- Reset one-time pass
	-- state.coins = 2000

	-- get player naem
	if TestConfig.IsDev(player.Name) then
		state.skips.amount = 2000
	end
end

-- Export this function so WorldPortalService can call it
Shared.UpdateState = function(player: Player, action: UpdateState.UpdateStateAction)
	local profile = Profiles[player]
	if not profile then
		return
	end

	if action.type == "UpdateStage" then
		player.leaderstats.Stage.Value += action.amount
	elseif action.type == "ResetStage" then
		player.leaderstats.Stage.Value = 0
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

	Local.InitState(player)

	Local.CreateLeaderstats(player)

	if RunService:IsStudio() then
		task.delay(1, function()
			Shared.ProfileLoaded:Fire(player)
			local clientData = table.clone(profile.Data)
			Remotes.SetData:FireClient(player, clientData)
		end)
	end

	-- Run this if not in roblox studio
	if not RunService:IsStudio() then
		-- Pass the player and profile data to HandleWorldTeleport
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
