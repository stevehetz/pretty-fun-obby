-- local MaxJumps = 2
-- local jumpAnimationAssetId = "rbxassetid://112665726164183" -- Replace with your actual asset id

-- local UIS = game:GetService("UserInputService")
-- local Player = game:GetService("Players").LocalPlayer
-- local Char = Player.Character or Player.CharacterAdded:Wait()
-- local Humanoid = Char:WaitForChild("Humanoid")
-- local Animator = Humanoid:WaitForChild("Animator")

-- local NumJumps = 0
-- local hasReleasedJump = true -- ensure a new press is required to initiate another jump

-- -- Create and load jump animation
-- local jumpanimation = Instance.new("Animation")
-- jumpanimation.AnimationId = jumpAnimationAssetId
-- local jumptrack = Animator:LoadAnimation(jumpanimation)

-- -- Listen to state changes to update jump count and handle double jump animation
-- Humanoid.StateChanged:Connect(function(oldState, newState)
-- 	if newState == Enum.HumanoidStateType.Landed then
-- 		-- Reset jump count when the character lands
-- 		NumJumps = 0
-- 	elseif newState == Enum.HumanoidStateType.Jumping then
-- 		-- Increase jump count whenever the humanoid begins a jump
-- 		NumJumps = NumJumps + 1
-- 		if NumJumps == 2 then
-- 			-- Play double jump animation on the second jump
-- 			jumptrack:Play()
-- 		end
-- 	end
-- end)

-- -- Utility function to determine if an input qualifies as a jump action
-- local function isJumpInput(input)
-- 	if input.UserInputType == Enum.UserInputType.Keyboard then
-- 		return input.KeyCode == Enum.KeyCode.Space
-- 	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
-- 		return input.KeyCode == Enum.KeyCode.ButtonA
-- 	elseif input.UserInputType == Enum.UserInputType.Touch then
-- 		return true -- Any touch is considered a jump input
-- 	end
-- 	return false
-- end

-- -- Use InputBegan and InputEnded for discrete jump detection across devices
-- UIS.InputBegan:Connect(function(input)
-- 	if isJumpInput(input) then
-- 		-- Only allow a jump input if this is either a double jump (NumJumps > 0)
-- 		-- or the first jump is initiated from a grounded state.
-- 		if NumJumps == 0 then
-- 			local state = Humanoid:GetState()
-- 			if state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.Landed then
-- 				return
-- 			end
-- 		end

-- 		if hasReleasedJump and NumJumps < MaxJumps then
-- 			hasReleasedJump = false -- lock until the button is released
-- 			Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
-- 		end
-- 	end
-- end)

-- UIS.InputEnded:Connect(function(input)
-- 	if isJumpInput(input) then
-- 		hasReleasedJump = true -- allow a new jump press once the button is lifted
-- 	end
-- end)
