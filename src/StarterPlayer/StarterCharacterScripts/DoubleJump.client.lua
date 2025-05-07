local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerScripts = Player:WaitForChild("PlayerScripts")
local StateController = require(PlayerScripts:WaitForChild("Controllers"):WaitForChild("StateController"))

local MaxJumps = 2
local jumpAnimationAssetId = "rbxassetid://136637623641505" -- Replace with your actual asset id

local UIS = game:GetService("UserInputService")
local PlayerGui = Player:WaitForChild("PlayerGui")
local Char = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Char:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")

-- Reference to the jump button in the mobile controls
local jumpButton

local NumJumps = 0
local hasReleasedJump = true -- ensure a new press is required to initiate another jump

-- Create and load jump animation
local jumpanimation = Instance.new("Animation")
jumpanimation.AnimationId = jumpAnimationAssetId
local jumptrack = Animator:LoadAnimation(jumpanimation)

local doubleJumpGamePassId = 1160545563 -- Replace with your actual gamepass ID
local hasDoubleJump = false -- Flag to check if double jump is available

function OnStart()
	SetState()

	-- Find the jump button in the mobile controls
	local function findJumpButton()
		local mobileControls = PlayerGui:FindFirstChild("MobileControls") or PlayerGui:FindFirstChild("TouchGui")
		if mobileControls then
			jumpButton = mobileControls:FindFirstChild("JumpButton", true)
				or mobileControls:FindFirstChild("Jump", true)
			if not jumpButton then
				-- Look for any button that might be the jump button based on common naming patterns
				for _, obj in pairs(mobileControls:GetDescendants()) do
					if
						obj:IsA("GuiObject") and (string.find(string.lower(obj.Name), "jump") or obj.Name == "Button1")
					then
						jumpButton = obj
						break
					end
				end
			end
		end
	end

	-- Try to find the jump button immediately
	findJumpButton()

	-- If not found, wait for the mobile controls to be added
	if not jumpButton then
		PlayerGui.ChildAdded:Connect(function(child)
			if child.Name == "MobileControls" or child.Name == "TouchGui" then
				findJumpButton()
			end
		end)
	end

	StateController.UpdateState.Event:Connect(function(action)
		if action.type == "UpdateGamepass" then
			SetState()
		end
	end)

	-- Listen to state changes to update jump count and handle double jump animation
	Humanoid.StateChanged:Connect(function(oldState, newState)
		if not hasDoubleJump then
			return -- No double jump available, exit early
		end

		if newState == Enum.HumanoidStateType.Landed then
			-- Reset jump count when the character lands
			NumJumps = 0
		elseif newState == Enum.HumanoidStateType.Jumping then
			-- Increase jump count whenever the humanoid begins a jump
			NumJumps = NumJumps + 1
			if NumJumps == 2 then
				-- Play double jump animation on the second jump
				jumptrack:Play()
			end
		end
	end)

	-- Use InputBegan and InputEnded for discrete jump detection across devices
	UIS.InputBegan:Connect(function(input)
		if not hasDoubleJump then
			return -- No double jump available, exit early
		end

		if isJumpInput(input) then
			-- Only allow a jump input if this is either a double jump (NumJumps > 0)
			-- or the first jump is initiated from a grounded state.
			if NumJumps == 0 then
				local state = Humanoid:GetState()
				if state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.Landed then
					return
				end
			end

			if hasReleasedJump and NumJumps < MaxJumps then
				hasReleasedJump = false -- lock until the button is released
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if not hasDoubleJump then
			return -- No double jump available, exit early
		end

		if isJumpInput(input) then
			hasReleasedJump = true -- allow a new jump press once the button is lifted
		end
	end)
end

-- Utility function to determine if an input qualifies as a jump action
function isJumpInput(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return input.KeyCode == Enum.KeyCode.Space
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		return input.KeyCode == Enum.KeyCode.ButtonA
	elseif input.UserInputType == Enum.UserInputType.Touch then
		-- Only consider touches on the jump button as jump inputs
		if jumpButton then
			local touchPosition = input.Position
			local jumpButtonAbsolutePosition = jumpButton.AbsolutePosition
			local jumpButtonAbsoluteSize = jumpButton.AbsoluteSize

			-- Check if the touch is within the bounds of the jump button
			return touchPosition.X >= jumpButtonAbsolutePosition.X
				and touchPosition.X <= jumpButtonAbsolutePosition.X + jumpButtonAbsoluteSize.X
				and touchPosition.Y >= jumpButtonAbsolutePosition.Y
				and touchPosition.Y <= jumpButtonAbsolutePosition.Y + jumpButtonAbsoluteSize.Y
		end
		return false
	end
	return false
end

function SetState()
	local success, state = pcall(function()
		return StateController.GetState()
	end)

	if not success then
		print("Error calling GetState:", state)
		return
	end

	if not state then
		print("State is nil, returning early")
		return
	end

	-- Check if the gamepass exists by ID (1160545563 from Store.lua)
	-- if state.gamepasses[tostring(doubleJumpGamePassId)] then
	-- 	hasDoubleJump = true
	-- else
	-- 	hasDoubleJump = false
	-- end

	-- Enable for everyone
	hasDoubleJump = true
end

OnStart()
