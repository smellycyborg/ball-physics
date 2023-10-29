local RunService = game:GetService("RunService")

local Classes = script.Parent

local Bezier = require(Classes.BetterBezier)

local USING_ASSEMBLY = true
local USER_VECTOR = false
local WITH_CURVE = true
local USE_RAY_CHECK = false

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
    movementPart.Size = Vector3.new(6, 6, 6)
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
    vectorForce.Name = "VectorForce"
    vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.new(0, movementPart:GetMass() * workspace.Gravity, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Attachment0 = attachment0

    local attachment1 = Instance.new("Attachment")
    attachment1.Name = "Attachment1"

    -- local angularVelocity = Instance.new("AngularVelocity", movementPart)
    -- angularVelocity.Name = "AngularVelocity"
    -- angularVelocity.Attachment0 = attachment0

    -- local linearVelocity = Instance.new("BodyVelocity", movementPart)
    -- linearVelocity.Velocity = Vector3.new(0, 0, 0) 
    -- linearVelocity.MaxForce = Vector3.new(0, movementPart:GetMass() * workspace.Gravity, 0)

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
    private.lastTarget = private.startingPart
    private.maxDistance = maxDistance
    private.timeUntilNextTarget = timeUntilNextTarget
    private.startSpeed = startSpeed
    private.maxSpeed = maxSpeed

    private.group = {}
    private.path = {}

    private.canSetTarget = true
    private.canMove = true
    private.index = 2
    private.t = 0
    private.timesHit = 1.1
    private.points = 5
    private.offsetMul = 1
    private.speed = private.startSpeed
    private.actualSpeed = 0

    private.divisionNumber = 6

    movementPrivate[instance] = private

    return setmetatable(instance, movementPrototype)
end

function movementPrototype:startMovement()
    self:setTarget()
    self:startDistanceCheck()
end

function movementPrototype:hasHit()
    local private = movementPrivate[self]

    if USE_RAY_CHECK then
        local direction = private.movementPart.Velocity.Unit
        local distance = private.movementPart.Velocity.Magnitude * (1/60)
        local ray = Ray.new(private.movementPart.Position, direction * distance)

        local hitPart, hitPosition = workspace:FindPartOnRay(ray, private.movementPart, true, false)

        warn(hitPart)

        if hitPart then
            if hitPart == private.mainTarget or private.mainTarget.Parent:FindFirstChild(hitPart) then
                return true
            else
                return false
            end
        else
            return false
        end
    else
        local distance = (private.mainTarget.Position - private.movementPart.Position).Magnitude
        if distance <= private.maxDistance then
            return true
        else
            return false
        end
    end
end

function movementPrototype:setLinearVelocity()
    local private = movementPrivate[self]

    if not private.mainTarget then
        return warn("Target has been destroyed.")
    end

    if WITH_CURVE then
        private.offset = (private.offsetMul * private.offsetForce)
    end

    local direction = WITH_CURVE and (private.mainTarget.Position - private.movementPart.Position).Unit 
        or (private.mainTarget.Position - private.lastTarget.Position).Unit
    local velocity = WITH_CURVE and (direction + private.offset) * private.actualSpeed
        or direction * private.actualSpeed

    private.movementPart.AssemblyLinearVelocity = velocity

    if WITH_CURVE then
        local remainingDistance = (private.mainTarget.Position - private.movementPart.Position).Magnitude
        local totalDistance = (private.mainTarget.Position - private.lastTarget.Position).Magnitude
        local progress = 1 - (remainingDistance / totalDistance)

        private.offsetMul = math.min(remainingDistance / totalDistance, 1)
    end
end

function movementPrototype:setVectorVelocity()
    local private = movementPrivate[self]

    if not private.mainTarget then
        return warn("Target has been destroyed.")
    end
end

function movementPrototype:startDistanceCheck()
    local private = movementPrivate[self]

    RunService.Heartbeat:Connect(function(_step)
        if isTasking then
            return
        end

        isTasking = true

        if not private.mainTarget then
            self:reset() 
            return warn("Target has been destroyed.")
        end

        local hasHit = self:hasHit()
        if hasHit then
            self:setTarget()
        else
            if USING_ASSEMBLY then
                self:setLinearVelocity()
            end
        end

        isTasking = false
    end)
end

function movementPrototype:setTarget()
    local private = movementPrivate[self]

    if not private.canSetTarget then
        return
    end

    if not next(private.group) then
        self:setTarget()

        return
    end

    local randomIndex = #private.group > 1 and math.random(1, #private.group) or 1
    local targetRootPart = self:getTargetRootPart(private.group[randomIndex])
    if not targetRootPart then
        self:setTarget()
        
        return
    end

    -- set velocity to zero
    if USING_ASSEMBLY then  
        private.movementPart.AssemblyLinearVelocity = Vector3.zero
        private.movementPart.Velocity = Vector3.zero
    elseif USING_VECTOR then
        private.movementPart.VectorForce.Force = Vector3.zero
    end
    if private.movementPart:FindFirstChild("AngularVelocity") then
        private.movementPart.AngularVelocity.AngularVelocity = Vector3.zero
    end
    -- private.movementPart.Velocity = Vector3.zero

    -- private.movementPart.Velocity = Vector3.new(0, 0, 0)
    private.path = {}
    private.index = 1
    private.offsetMul = 1
    private.lastTarget = private.mainTarget
    private.mainTarget = targetRootPart

    -- set offset
    if WITH_CURVE then
        private.offsetForce = private.lastTarget.CFrame.LookVector.Unit
    end

     -- set speed
     if private.speed >= private.maxSpeed then
        private.speed = private.maxSpeed
     else
        private.speed = private.speed + private.speed / private.divisionNumber
     end
     private.actualSpeed = math.clamp(private.speed, private.startSpeed, private.maxSpeed)

     -- check if targets are far enough to create curve
     local distanceBetweenTargets = (private.mainTarget.Position - private.lastTarget.Position).Magnitude
     if distanceBetweenTargets < 50 then
        WITH_CURVE = false
     else
        WITH_CURVE = true
     end
end

function movementPrototype:reset()
    local private = movementPrivate[self]

    if USING_ASSEMBLY then  
        private.movementPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    elseif USING_VECTOR then
        private.movementPart.VectorForce.Force = Vector3.new(0, 0, 0)
    end

    if private.movementPart:FindFirstChild("AngularVelocity") then
        private.movementPart.AngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
    end

    private.movementPart.CFrame = CFrame.new(private.startingPart.Position)
    private.mainTarget = private.startingPart

    if not next(private.group) then
        return
    end

    private.speed = private.startSpeed

    task.delay(private.timeUntilNextTarget, function()

        self:setTarget()
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