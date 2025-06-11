local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

export type SoundName = "Checkpoint" | "Confirm" | "Error" | "Menu-Click" | "Rebirth" | "Music" | "CoinCollect" | "Dink"

local Local = {}
local Shared = {}

function Shared.GetSound(sound: SoundName): Sound
	return ReplicatedStorage.Sounds[sound]:Clone()
end

function Shared.PlaySound(soundName: SoundName, part: Part | Attachment?)
	local sound = Shared.GetSound(soundName)

	if part then
		sound.Parent = part
	else
		sound.Parent = Workspace
	end

	sound:Play()
	sound.Ended:Wait()
	sound:Destroy()
end

-- Play sound only if the player has sound effects enabled
function Shared.PlaySoundForServer(soundName: SoundName, player: Player, part: Part | Attachment?)
	-- Check if we're running on the server
	if game:GetService("RunService"):IsServer() then
		-- Get PlayerDataService only when on server to avoid client errors
		local PlayerDataService = require(ServerScriptService.Services.PlayerDataService)

		-- Get player state
		local state = PlayerDataService.GetState(player)
		if not state then
			return
		end

		-- Check if sound effects are enabled for this player
		local soundEffectsEnabled = state.settings["Sound Effects"]
		if not soundEffectsEnabled then
			return -- Don't play sound if disabled
		end
	end

	-- If we're on client or sound effects are enabled, play the sound
	Shared.PlaySound(soundName, part)
end

return Shared
