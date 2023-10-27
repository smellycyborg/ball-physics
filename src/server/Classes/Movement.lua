local RunService = game:GetService("RunService")

local Classes = script.Parent

local Bezier = require(Classes.Bezier)

local movement = {}
local movementPrototype = {}
local movementPrivate = {}

local function _createInstances(startingPosition)
    local startingPart = Instance.new("Part", workspace)
    startingPart.Transparency = 1
    startingPart.Name = "StartingPart"
    startingPart.Size = Vector3.new(1, 1, 1)
    startingPart.CanCollide = false
    startingPart.BrickColor = BrickColor.new("Cyan")
    startingPart.Anchored = true
    startingPart.Position = startingPosition

    local attachment1 = Instance.new("Attachment", startingPart)
    attachment1.Name = "Attachment1"

    local movementPart = Instance.new("Part")
    movementPart.Name = "MovementPart"
    movementPart.Size = Vector3.new(5, 5, 5)
    movementPart.Massless = true
    movementPart.Anchored = false
    movementPart.Shape = "Ball"
    movementPart.BrickColor = BrickColor.new("Persimmon")
    movementPart.Position = startingPosition
    movementPart.CanCollide = false

    local highlight = Instance.new("Highlight", movementPart)
    highlight.FillColor = Color3.fromRGB(255, 178, 178)
    highlight.FillTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded

    local attachment0 = Instance.new("Attachment", movementPart)
    attachment0.Name = "Attachment0"

    local vectorForce = Instance.new("VectorForce", movementPart)
    vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.new(0, movementPart:GetMass() * workspace.Gravity, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Attachment0 = attachment0

    local pointB = Instance.new("Part")
    pointB.Name = "PointB"
    pointB.Anchored = true
    pointB.Size = Vector3.new(2, 2, 2)
    pointB.BrickColor = BrickColor.new("Lapis")
    pointB.Transparency = 1
    pointB.CanCollide = false

    startingPart.Parent = workspace
    attachment1.Parent = startingPart
    movementPart.Parent = workspace
    pointB.Parent = workspace

    return movementPart, startingPart, pointB
end

function movement.new(
    startingPosition: Vector3, 
    maxDistance: Number, 
    timeUntilNextTarget: Number,
    startSpeed: Number,
    maxSpeed: Number
)

    local instance = {}
    local private = {}

    private.movementPart, private.startingPart, private.pointB = _createInstances(startingPosition)

    private.mainTarget = private.startingPart
    private.maxDistance = maxDistance
    private.timeUntilNextTarget = timeUntilNextTarget
    private.startSpeed = startSpeed
    private.maxSpeed = maxSpeed

    private.group = {}
    private.path = {}

    private.canSetTarget = true
    private.canMove = true
    private.index = 2
    private.timesHit = 1.1
    private.speed = private.startSpeed

    private.divisionNumber = 3

    movementPrivate[instance] = private

    return setmetatable(instance, movementPrototype)
end

function movementPrototype:startMovement()
    self:setTarget()

    -- self:setCurve()
    self:startDistanceCheck()

end

function movementPrototype:setCurve()
    local private = movementPrivate[self]

    local direction = (private.mainTarget.position - private.movementPart.Position).Unit

    local pointBPosition = private.movementPart.Position + direction * math.random(1, 50)

    if math.abs(direction.X) > math.abs(direction.Z) then
        -- If the line is predominantly along the X-axis

        pointBPosition = pointBPosition + Vector3.new(0, 0, math.random(1, 50))
    else
        -- If the line is predominantly along the Z-axis

        pointBPosition = pointBPosition + Vector3.new(math.random(1, 50), 0, 0)
    end

    private.pointB.CFrame = CFrame.new(pointBPosition)

    local curve = Bezier.new(private.movementPart.Position, private.pointB.Position, private.mainTarget.Position)
    
    private.path = curve:GetPath(0.2)

    -- print("setCurve:  have successful set a path for movement -> ", private.path)
end

function movementPrototype:setVectorVelocity()
    local private = movementPrivate[self]

    if not private.mainTarget then
        return warn("Target has been destroyed.")
    end

    -- local isPath = #private.path >= private.index
    -- if isPath then
    --     local distanceBetweenMovementPartAndTarget = (private.path[private.index] - private.movementPart.Position).Magnitude
    --     if distanceBetweenMovementPartAndTarget <= 2 then
    --         private.index += 1
    --     end
    -- end

    -- local toTarget = not isPath and private.mainTarget.Position or private.path[private.index]

    local direction = (private.mainTarget.Position - private.movementPart.Position).Unit

    private.movementPart.AssemblyLinearVelocity = direction * private.speed
end

function movementPrototype:startDistanceCheck()
    local private = movementPrivate[self]
    
    local isTasking = false

    RunService.Heartbeat:Connect(function(step)
        if isTasking then
            return
        end
    
        isTasking = true

        if not private.mainTarget then
            return warn("Target has been destroyed.")
        end

        if not private.path then
            return warn("There is no path.")
        end

        local distanceBetweenPartAndTarget = (private.mainTarget.Position - private.movementPart.Position).Magnitude

        if distanceBetweenPartAndTarget <= private.maxDistance then
            self:setTarget()
            -- self:setCurve()

            -- self:reset()
        else
            self:setVectorVelocity()
        end
    
        isTasking = false
    end)
end

function movementPrototype:reset()
    local private = movementPrivate[self]

    private.movementPart.AssemblyLinearVelocity= Vector3.new(0, 0, 0)
    private.movementPart.CFrame = CFrame.new(private.startingPart.Position)
    private.mainTarget = private.startingPart

    if not next(private.group) then
        return
    end

    private.speed = private.startSpeed

    task.delay(private.timeUntilNextTarget, function()

        self:setTarget()
        -- self:setCurve()
    end)
end

function movementPrototype:addPlayerToMovementGroup(player)
    local private = movementPrivate[self]

    table.insert(private.group, player)
end

function movementPrototype:removePlayerFromMovementGroup(player)
    local private = movementPrivate[self]

    table.remove(private.group, table.find(private.group, player))
end

function movementPrototype:setTarget()
    local private = movementPrivate[self]

    if not private.canSetTarget then
        return
    end

    if not next(private.group) then
        self:setTarget()
        -- self:setCurve()

        return
    end

    local randomIndex = #private.group > 1 and math.random(1, #private.group) or 1
    local targetRootPart = self:getTargetRootPart(private.group[randomIndex])
    if not targetRootPart then
        self:setTarget()
        -- self:setCurve()
        
        return
    end

    private.mainTarget = targetRootPart

    private.speed = private.speed + private.speed / private.divisionNumber

    -- private.divisionNumber = private.divisionNumber + private.divisionNumber / 3

    if private.speed >= private.maxSpeed then
        private.speed = private.maxSpeed
    end

    -- warn("Speed:  ", private.speed)
end

function movementPrototype:getTargetRootPart(target)
    local private = movementPrivate[self]

    if target == private.startingPart or target.ClassName == "BasePart" or target.ClassName == "Part" then
        return target
    end

    local character = target.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end

    local targetIsDead = humanoid.Health < 0
    if targetIsDead then
        return 
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end

    return humanoidRootPart
end

function movementPrototype:destroy()
    self:destroy()
end

movementPrototype.__index = movementPrototype
movementPrototype.__metatable = "This metatable is locked."
movementPrototype.__newindex = function(_, _, _)
    error("This metatable is locked.")
end

return movement