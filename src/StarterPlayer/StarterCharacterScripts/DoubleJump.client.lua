local MaxJumps = 2
local JumpCooldown = 0.1
local jumpAnimationAssetId = "rbxassetid://112665726164183" -- Replace with your actual asset id

local UIS = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local NumJumps = 0
local canjump = false

-- Dynamically create a new Animation instance using the asset id
local jumpanimation = Instance.new("Animation")
jumpanimation.AnimationId = jumpAnimationAssetId

local jumptrack = Animator:LoadAnimation(jumpanimation)

Humanoid.StateChanged:Connect(function(oldstate, newstate)
	if newstate == Enum.HumanoidStateType.Landed then
		NumJumps = 0
		canjump = false
	elseif newstate == Enum.HumanoidStateType.Freefall then
		wait(JumpCooldown)
		canjump = true
	elseif newstate == Enum.HumanoidStateType.Jumping then
		canjump = false
		NumJumps = NumJumps + 1
	end
end)

UIS.JumpRequest:Connect(function()
	if canjump and NumJumps < MaxJumps then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		jumptrack:Play()
	end
end)
