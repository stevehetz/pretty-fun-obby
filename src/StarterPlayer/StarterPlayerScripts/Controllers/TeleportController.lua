local Players = game:GetService("Players")
local DebrisService = game:GetService("Debris")

local StateController = require(script.Parent.StateController)

local player = Players.LocalPlayer

local Local = {}
local Shared = {}

function Shared.OnStart()
	StateController.UpdateState.Event:Connect(function(action: StateController.UpdateStateAction)
		-- Get Player State
		if action.type == "UpdateTeleporting" and action.origin == "Portal" then
			local char = player.Character
			if not char then
				return
			end
			local head = char:FindFirstChild("Head")
			if not head then
				return
			end

			-- create a BillboardGui
			local bill = Instance.new("BillboardGui")
			bill.Adornee = head
			bill.AlwaysOnTop = true
			bill.StudsOffset = Vector3.new(0, 2, 0)
			bill.Size = UDim2.new(0, 200, 0, 50)
			bill.Parent = head

			-- add a TextLabel
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "Teleporting..."
			label.TextScaled = true
			label.Font = Enum.Font.SourceSansBold
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Parent = bill

			DebrisService:AddItem(bill, 10)
		end
	end)
end

return Shared
