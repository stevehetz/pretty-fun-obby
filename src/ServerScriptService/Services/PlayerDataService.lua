local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local PlayerData = require(ReplicatedStorage.PlayerData)
local GlobalDataService = require(ServerScriptService.Services.GlobalDataService)
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

Local.TeleportEventInitialized = false

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

			-- Create a deep copy of the data to avoid cyclic references
			local clientData = table.clone(data)
			Remotes.SetData:FireClient(player, clientData)
		end
	end)

	-- if no roblox studio
	if not RunService:IsStudio() then
		WorldPortalService.HandleWorldTeleportComplete.Event:Connect(
			function(player: Player, state: PlayerData.PlayerData)
				print("PlayerDataService - HandleWorldTeleportComplete.Event:Connect")

				-- print("PlayerDataService - HandleWorldTeleportComplete:Connect")
				-- GlobalDataService.RecordFinish(player, profile.Data.finishes)

				-- print("PlayerDataService - ProfileLoaded:Fire")
				Shared.ProfileLoaded:Fire(player)

				-- print("PlayerDataService - Remotes.SetData:FireClient")

				-- Create a deep copy of the state to avoid cyclic references
				local clientState = table.clone(state)
				Remotes.SetData:FireClient(player, clientState)

				WorldPortalService.SetupPortals()
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
		-- profile.Data.skips.amount = 2000
		return profile.Data
	end

	return nil
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

	if action.type == "UpdateFinishes" then
		local newTotalFinishes = profile.Data.finishes + action.amount
		player.leaderstats.Finishes.Value = newTotalFinishes
		GlobalDataService.RecordFinish(player, newTotalFinishes)
	end

	if action.type == "UpdateCurrentWorld" then
		local displayName = WorldsConfig.GetDisplayNameFromWorldName(action.world)
		player.leaderstats.CurrentWorld.Value = displayName or "World 1"
	end

	UpdateState(profile.Data, action)

	-- Create a clean copy of the action to send to the client
	-- This prevents cyclic references
	local clientAction = {
		type = action.type,
	}

	-- Copy only the necessary fields based on action type
	if action.type == "UpdateStage" then
		clientAction.amount = action.amount
	elseif action.type == "ResetStage" then
		-- No additional fields needed
	elseif action.type == "UpdateDeaths" then
		clientAction.amount = action.amount
	elseif action.type == "UpdateSetting" then
		clientAction.setting = action.setting
		clientAction.value = action.value
	elseif action.type == "EarnSkip" then
		clientAction.amount = action.amount
	elseif action.type == "UpdateVip" then
		clientAction.value = action.value
	elseif action.type == "UpdateGamepass" then
		clientAction.value = action.value
		clientAction.gamepassId = action.gamepassId
	elseif action.type == "UpdateFinishes" then
		clientAction.amount = action.amount
	elseif action.type == "UpdateWorldFinishes" then
		clientAction.world = action.world
		clientAction.amount = action.amount
	elseif action.type == "UpdateTeleporting" then
		clientAction.world = action.world
		clientAction.origin = action.origin
	elseif action.type == "UpdateCurrentWorld" then
		clientAction.world = action.world
	end

	-- print("PlayerDataService - UpdateData - FireClient")
	Remotes.UpdateData:FireClient(player, clientAction)
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
		task.delay(1, function()
			-- GlobalDataService.RecordFinish(player, profile.Data.finishes)
			-- print("PlayerDataService - ProfileLoaded:Fire")
			Shared.ProfileLoaded:Fire(player)
			-- print("PlayerDataService - CreateProfile - Remotes.SetData:FireClient")

			-- Create a deep copy of the data to avoid cyclic references
			local clientData = table.clone(profile.Data)
			Remotes.SetData:FireClient(player, clientData)

			WorldPortalService.SetupPortals()
		end)

		-- task.delay(3, function()
		-- 	local value = GlobalDataService.GetTopFinishers(player)
		-- 	print("Top Finishers: ", value)
		-- end)
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
