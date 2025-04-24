local elevator = game.Workspace.Stages["13"].Elevator
task.wait(2)

-- Make sure the model has a PrimaryPart set
if not elevator.PrimaryPart then
	elevator.PrimaryPart = elevator:FindFirstChildWhichIsA("BasePart")
end

while true do
	-- move up 300 steps
	for i = 1, 280 do
		-- Use SetPrimaryPartCFrame to move the entire model
		local currentCFrame = elevator.PrimaryPart.CFrame
		elevator:SetPrimaryPartCFrame(currentCFrame + Vector3.new(0, 0.3, 0))
		task.wait()
	end
	task.wait(4)

	-- move down 300 steps
	for i = 1, 280 do
		-- Use SetPrimaryPartCFrame to move the entire model
		local currentCFrame = elevator.PrimaryPart.CFrame
		elevator:SetPrimaryPartCFrame(currentCFrame + Vector3.new(0, -0.3, 0))
		task.wait()
	end
	task.wait(4)
end
