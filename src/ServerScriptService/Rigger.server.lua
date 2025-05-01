-- local pet = script.Parent

-- for _, v in pet:GetDescendants() do
-- 	if v:IsA("Weld") or v:IsA("WeldConstraint") then
-- 		v:Destroy()
-- 	end
-- 	if v:IsA("BasePart") then
-- 		v.Anchored = true
-- 		v.CanCollide = false
-- 	end
-- end

-- local cf, size = pet:GetBoundingBox()

-- local primaryPart = Instance.new("Part")
-- primaryPart.Name = "Primary"
-- primaryPart.Size = size
-- primaryPart.Parent = pet
-- primaryPart.Anchored = true
-- primaryPart.CFrame = cf
-- primaryPart.Transparency = 1
-- primaryPart.CanCollide = false

-- pet.PrimaryPart = primaryPart

-- for _, v in pet:GetDescendants() do
-- 	if v:IsA("BasePart") and v ~= primaryPart then
-- 		local weld = Instance.new("WeldConstraint")
-- 		weld.Part0 = primaryPart
-- 		weld.Part1 = v
-- 		weld.Name = v.Name
-- 		weld.Parent = primaryPart
-- 		v.Anchored = false
-- 		v.CanCollide = false
-- 	end
-- end
