local Local = {}
local Shared = {}

local animateSpeed = 0.2

function Shared.Create(animationAssetId: string, rig: Model)
	local EnemyAnimate = {}
	EnemyAnimate.__index = EnemyAnimate

	function EnemyAnimate.new(animationAssetId: string, rig: Model)
		local self = setmetatable({}, EnemyAnimate)

		self.animationAssetId = animationAssetId
		self.rig = rig
		self.isAnimationPlaying = false

		local animation = Instance.new("Animation")
		animation.AnimationId = animationAssetId
		animation.Parent = rig.Humanoid

		local animator = rig.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", rig.Humanoid)

		self.animTrack = animator:LoadAnimation(animation)
		self.animTrack.Priority = Enum.AnimationPriority.Action

		self.animTrack:GetMarkerReachedSignal("Pause"):Connect(function()
			if self.isAnimationPlaying then
				self.animTrack:AdjustSpeed(0)
			else
				self.animTrack:AdjustSpeed(animateSpeed)
			end
		end)

		return self
	end

	function EnemyAnimate:play()
		if not self.isAnimationPlaying then
			self.animTrack:AdjustSpeed(animateSpeed)
			self.animTrack:Play()
			self.isAnimationPlaying = true
		end
	end

	function EnemyAnimate:stop()
		if self.isAnimationPlaying then
			self.animTrack:AdjustSpeed(animateSpeed)
			self.isAnimationPlaying = false
		end
	end

	return EnemyAnimate.new(animationAssetId, rig)
end

return Shared
