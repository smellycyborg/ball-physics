local RunService = game:GetService("RunService")

local movement = {}
local movementPrototype = {}
local movementPrivate = {}

local function _createInstances(startingPosition)
    local movementPart = Instance.new("Part", workspace)
    movementPart.Name = "MovementPart"
    movementPart.Size = Vector3.new(0.2, 0.2, 0.2)
    movementPart.Massless = true
    movementPart.Anchored = false
    movementPart.Shape = "Ball"

    local attachment0 = Instance.new("Attachment", movementPart)
    attachment0.Name = "Attachment0"

    local vectorForce = Instance.new("VectorForce", movementPart)
    vectorForce.Name = "VectorForce"
    vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
    vectorForce.Attachment0 = attachment0

    local startingPart = Instance.new("Part", workspace)
    startingPart.Name = "StartingPart"
    startingPart.Size = Vector3.new(1, 1, 1)
    startingPart.Position = startingPosition

    local attachment1 = Instance.new("Attachment", startingPart)
    attachment1.Name = "Attachment1"

    local alignPosition = Instance.new("AlignPosition", movementPart)
    alignPosition.Name = "AlignPosition"
    alignPosition.Responsiveness = 5
    alignPosition.Attachment0 = attachment0
    alignPosition.Attachment1 = attachment1
    alignPosition.MaxForce = 10000

    return movementPart, startingPart
end

function movement.new(startingPosition, maxDistance)
    local instance = {}
    local private = {}

    private.movementPart, private.startingPart = _createInstances(startingPosition)

    private.group = {}

    private.target = private.startingPart
    private.maxDistance = maxDistance

    movementPrivate[instance] = private

    return setmetatable(instance, movementPrototype)
end

function movementPrototype:getTargetRootPart(target)
    local private = movementPrivate[self]

    if target == private.startingPart then
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

function movementPrototype:startDistanceCheck()
    local private = movementPrivate[self]
    
    local isTasking = false 

    RunService.Heartbeat:Connect(function(step)
        if isTasking then
            return
        end
    
        isTasking = true
    
        local targetRootPart = self:getTargetRootPart(private.target)
        local distanceBetweenPartAndTarget = (targetRootPart.Position - private.movementPart.Position).Magnitude
        if distanceBetweenPartAndTarget >= private.maxDistance then
            self:setTarget()
        end
    
        isTasking = false
    end)
end

function movementPrototype:setTarget()
    local private = movementPrivate[self]

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

    local targetAttachment = targetRootPart:FindFirstChild("Attachment1")
    if not targetAttachment then
        self:setTarget()

        return
    end

    local attachment1 = targetRootPart:FindFirstChild("Attachment1")
    if not attachment1 then
        self:setTarget()

        return
    end

    local alignPosition = private.movementPart:FindFirstChild("AlignPosition")
    if not alignPosition then
        return
    end

    alignPosition.Attachment1 = targetAttachment
end

function movementPrototype:addPlayerToMovementGroup(player)
    local private = movementPrivate[self]

    table.insert(private.group, player)
end

function movementPrototype:removePlayerFromMovementGroup(player)
    local private = movementPrivate[self]

    table.remove(private.group, table.find(private.group, player))
end

function movementPrototype:reset()
    local private = movementPrivate[self]

    private.part.CFrame = CFrame.new(private.startPosition)
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