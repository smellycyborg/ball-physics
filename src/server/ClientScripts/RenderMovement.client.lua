-- local RunService = game:GetService("RunService")

-- local serverPart = workspace:WaitForChild("MovementPart")

-- local movementPart = Instance.new("Part")
-- movementPart.Name = "MovementPart"
-- movementPart.Size = Vector3.new(6, 6, 6)
-- movementPart.Anchored = false
-- movementPart.Shape = "Ball"
-- movementPart.Anchored = false
-- movementPart.Massless = true
-- movementPart.Position = serverPart.Position
-- movementPart.BrickColor = BrickColor.new("Persimmon")
-- movementPart.CanCollide = false
-- movementPart.Parent = workspace

-- local highlight = Instance.new("Highlight", movementPart)
-- highlight.FillColor = Color3.fromRGB(255, 178, 178)
-- highlight.FillTransparency = 0.1
-- highlight.DepthMode = Enum.HighlightDepthMode.Occluded

-- local weld = Instance.new("Weld")
-- weld.Part0 = movementPart
-- weld.Part1 = serverPart
-- weld.Parent = movementPart

-- RunService.RenderStepped:Connect(function(step)
--     local serverPart = workspace:FindFirstChild("MovementPart")
--     if not serverPart then
--         return
--     end

--     movementPart.Position = serverPart.Position
-- end)