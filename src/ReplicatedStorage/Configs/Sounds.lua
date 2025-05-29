local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type SoundName = "Checkpoint" | "Confirm" | "Error" | "Menu-Click" | "Rebirth" | "Music" | "CoinCollect"

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

return Shared
