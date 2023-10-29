local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Signal = require(Packages.signal)

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
    movementPart.Size = Vector3.new(2, 2, 2)
    movementPart.Massless = false
    movementPart.Anchored = false
    movementPart.Shape = "Ball"
    movementPart.Transparency = 1
    movementPart.Position = startingPosition
    movementPart.CanCollide = false

    local attachment0 = Instance.new("Attachment", movementPart)
    attachment0.Name = "Attachment0"

    local vectorForce = Instance.new("VectorForce", movementPart)
    vectorForce.Name = "VectorForce"
    vectorForce.ApplyAtCenterOfMass = true
	vectorForce.Force = Vector3.new(0, movementPart:GetMass() * workspace.Gravity, 0)
	vectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	vectorForce.Attachment0 = attachment0

    -- local gravity = Instance.new("VectorForce", movementPart)
    -- gravity.Name = "Gravity"
    -- gravity.Force = Vector3.zero -- 'target' is the target part, 'gravityStrength' is the strength of the gravitational pull
    -- gravity.RelativeTo = Enum.ActuatorRelativeTo.World
    -- gravity.ApplyAtCenterOfMass = true

    local attachment1 = Instance.new("Attachment")
    attachment1.Name = "Attachment1"

    startingPart.Parent = workspace
    attachment1.Parent = startingPart
    movementPart.Parent = workspace

    return movementPart, startingPart
end

local movement = {}
local movementPrototype = {}
local movementPrivate = {}

function movement.new(
    startingPosition: Vector3, 
    maxDistance: Number, 
    timeUntilNextTarget: Number,
    startSpeed: Number,
    maxSpeed: Number,
    distanceToBlock: Number
)

    local instance = {}
    local private = {}

    instance.killPlayer = Signal.new()

    private.movementPart, private.startingPart, private.pointB = _createInstances(startingPosition)

    private.lastTarget = private.startingPart
    private.maxDistance = maxDistance
    private.timeUntilNextTarget = timeUntilNextTarget
    private.startSpeed = startSpeed
    private.maxSpeed = maxSpeed
    private.distanceToBlock = distanceToBlock

    private.group = {}

    private.currentTarget = nil
    private.targetPlayer = nil

    private.speed = private.startSpeed
    private.speedIncrement = 50
    private.withCurve = true
    private.curveMul = 1
    private.curveForce = Vector3.zero
    private.divisionNumber = 6

    movementPrivate[instance] = private

    return setmetatable(instance, movementPrototype)
end

function movementPrototype:startMovement()
    self:setTarget()
    self:runTargetsHandle()
    self:runVelocityHandle()
end

function movementPrototype:setTarget(player, cameraCFrame)
    local private = movementPrivate[self]

    if private.targetPlayer ~= player then
        return
    end

    local distanceBetweenCurrentTarget = (private.currentTarget.Position - private.movementPart.Position).Magnitude
    if distanceBetweenCurrentTarget > private.distanceToBlock then
        return
    end

    local randomIndex = #private.group > 1 and math.random(1, #private.group) or 1
    local targetHitbox, targetPlayer = self:getTargetHitbox(private.group[randomIndex])
    if not targetHitbox or targetHitbox == private.currentTarget then
        self:setTarget()
        
        return warn("setTarget:  Could not find target's Hitbox.")
    end

    private.targetPlayer = player

    -- reset velocity for movement part
    -- private.movementPart.AssemblyLinearVelocity = Vector3.zero
    -- private.movementPart.Velocity = Vector3.zero

    -- set curve force
    private.curveForce = targetHitbox.Parent.ClassName ~= "Model" and private.currentTarget.CFrame.LookVector.Unit or cameraCFrame.LookVector.Unit
	if private.curveForce and private.curveForce.Y < 0 then
		private.curveForce *= Vector3.new(1, 0, 1)
	end

    private.curveMul = 1

    -- set target
    private.currentTarget = targetHitbox

    -- check if targets are far enough to create curve
    local distanceBetweenTargets = (private.currentTarget.Position - private.movementPart.Position).Magnitude
    if distanceBetweenTargets > 50 then
        private.withCurve = true
    else
        private.withCurve = false
    end

    private.curveForce = private.curveForce or Vector3.zero

	self:increaseSpeed()
end

function movementPrototype:updateVelocity()
    local private = movementPrivate[self]

	if not private.currentTarget then 
        return 
    end
	
	if private.curveMul > 0 then
		private.curveMul = math.clamp(private.curveMul - 0.1, 0, 1)
	end
	
	local directionForce = (private.currentTarget.Position - private.movementPart.Position).Unit * private.speed

    -- private.movementPart:FindFirstChild("Gravity").Force = (private.currentTarget.Position - private.movementPart.Position).Unit * 1000 -- 'target' is the target part, 'gravityStrength' is the strength of the gravitational pull
	
	private.movementPart.AssemblyLinearVelocity = not private.withCurve and directionForce or directionForce + (private.curveForce * private.speed * private.curveMul)
end

function movementPrototype:runVelocityHandle()
    RunService.Heartbeat:Connect(function(_step)
        local private = movementPrivate[self]
        
        if not private.movementPart then
            return
        end

        self:updateVelocity()
    end)
end

function movementPrototype:runTargetsHandle()
    RunService.Heartbeat:Connect(function(_step)
        local private = movementPrivate[self]
        
        if not private.movementPart then
            return warn("There is no movement part.")
        end

        if self:hasHit() then
            self:reset()

            self.killPlayer:Fire(private.targetPlayer)
        end
    end)
end

function movementPrototype:reset()
    local private = movementPrivate[self]

    private.movementPart.AssemblyLinearVelocity = Vector3.zero
    -- private.movementPart.Velocity = Vector3.zero

    private.movementPart.CFrame = CFrame.new(private.startingPart.Position)
    private.currentTarget = private.startingPart
    private.speed = private.startSpeed

    if not next(private.group) then
        return warn("There are no more group members.")
    end

    task.delay(private.timeUntilNextTarget, function()
        self:setTarget()
    end)
end

function movementPrototype:increaseSpeed()
    local private = movementPrivate[self]

    -- set actual speed
    if private.speed < private.maxSpeed then
        private.speed = math.clamp(private.speed + private.speedIncrement, private.startSpeed, private.maxSpeed)
    end
end

function movementPrototype:hasHit()
    local private = movementPrivate[self]

    if not private.currentTarget then
        return
    end

    local distance = (private.currentTarget.Position - private.movementPart.Position).Magnitude
    if distance <= private.maxDistance then
        return true
    else
        return false
    end
end

function movementPrototype:addPlayerToMovementGroup(player)
    local private = movementPrivate[self]

    table.insert(private.group, player)
end

function movementPrototype:removePlayerFromMovementGroup(player)
    local private = movementPrivate[self]

    table.remove(private.group, table.find(private.group, player))
end

function movementPrototype:getTargetHitbox(target)
    local private = movementPrivate[self]

    if target.ClassName == "BasePart" or target.ClassName == "Part" then
        return target:FindFirstChild("Hitbox")
    end

    local character = target.Character
    if not character then
        return warn("getTargetHitbox:  Attempt to index nil with target's character.")
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return warn("getTargetHitbox:  Attempt to index nil with target's Humanoid.")
    end

    local targetIsDead = humanoid.Health < 0
    if targetIsDead then
        return warn("getTargetHitbox:  Target is dead.")
    end

    local hitbox = character:FindFirstChild("Hitbox")
    if not hitbox then
        return warn("getTargetHitbox:  Target does not have a Hitbox.")
    end

    return hitbox
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