local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Classes = script.Parent
local FastCastFolder = ReplicatedStorage.FastCast

local Bezier = require(Classes.Bezier)
local FastCast = require(FastCastFolder.FastCastRedux)

local IS_TESTING = true

local movement = {}
local movementPrototype = {}
local movementPrivate = {}

local function _createParts(startPosition)
    local movementPart = Instance.new("Part", workspace)
    movementPart.Name = "MovementPart"
    movementPart.CanCollide = false
    movementPart.Massless = false
    movementPart.Anchored = true
    movementPart.TopSurface = Enum.SurfaceType.SmoothNoOutlines

    local centerPart = Instance.new("Part", workspace)
    centerPart.Name = "CenterPart"
    centerPart.Anchored = true
    centerPart.CanCollide = false
    centerPart.Position = startPosition

    local points = Instance.new("Folder", workspace)
    points.Name = "Points"

    local pointA = Instance.new("Part", points)
    pointA.Name = "PointA"
    pointA.Anchored = true
    pointA.CanCollide = false
    pointA.Massless = true

    local pointB = Instance.new("Part", points)
    pointB.Name = "PointB"
    pointB.Anchored = true
    pointB.CanCollide = false
    pointB.Massless = true

    local pointC = Instance.new("Part", points)
    pointC.Name = "PointC"
    pointC.Anchored = true
    pointC.CanCollide = false
    pointC.Massless = true

    return movementPart, points, centerPart
end

local function _getTargetRootPart(target)
    if IS_TESTING then
        return target
    end

    local character = target.character
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

function movement.new(startPosition, maxDistance)
    local instance = {}
    local private = {}

    instance.updateMovement = Instance.new("RemoteEvent")
    instance.updateMovementFireAll = instance.updateMovement:FireAllClients()

    private.group = {}
    private.curveList = {}

    private.startPosition = startPosition
    private.maxDistance = maxDistance
    private.target = nil

    private.part, private.points, private.lastTarget = _createParts(startPosition)

    movementPrivate[instance] = private

    return setmetatable(instance, movementPrototype)
end

function movementPrototype:choseRandomTargetFromGroup()
    local private = movementPrivate[self]

    local randomIndex = math.random(1, #private.group)

    private.target = private.group[randomIndex]
end

function movementPrototype:setMovementPath()
    local private = movementPrivate[self]

    local function getRandomPositionForPartB(partA, partC, isPathX)
        warn(partC.Position.Z, partA.Position.Z)

        local x = math.random(math.min(partA.Position.X, partC.Position.X), math.max(partA.Position.X, partC.Position.X))
        local y = math.random(math.min(partA.Position.Y, partC.Position.Y), math.max(partA.Position.Y, partC.Position.Y))
        local z = math.random(math.min(partA.Position.Z, partC.Position.Z), math.max(partA.Position.Z, partC.Position.Z))

        if isPathX then
            x = math.random(-70, 70)
        else
            z = math.random(-150, 150)
        end
        
        return Vector3.new(x, y, z)
    end

    local points = private.points
    local pointA = points.PointA
    local pointB = points.PointB
    local pointC = points.PointC

    local lastTarget = _getTargetRootPart(private.lastTarget)
    local targetRootPart = _getTargetRootPart(private.target)
    if not targetRootPart then
        repeat
            task.wait()

            self:choseRandomTargetFromGroup(private.group)

            local updatedPrivate = movementPrivate[self]

            targetRootPart = _getTargetRootPart(updatedPrivate.target)
        until targetRootPart
    end

    pointC.CFrame = CFrame.new(Vector3.new(
        targetRootPart.Position.X,
        targetRootPart.Position.Y,
        targetRootPart.Position.Z
    ))

    pointA.CFrame = CFrame.new(Vector3.new(
        lastTarget.Position.X,
        lastTarget.Position.Y,
        lastTarget.Position.Z
    ))

    local deltaX = pointC.Position.X - pointA.Position.X
    local deltaZ = pointC.Position.Z - pointA.Position.Z

    local isPathX = false
    if math.abs(deltaX) > math.abs(deltaZ) then
        isPathX = true

        print("The path is primarily along the X-axis.")
    else
        print("The path is primarily along the Z-axis.")
    end

    local randomPositionForPartB = getRandomPositionForPartB(targetRootPart, lastTarget, isPathX)

    pointB.CFrame = CFrame.new(Vector3.new(
        randomPositionForPartB.X,
        randomPositionForPartB.Y,
        randomPositionForPartB.Z
    ))

    local curve = Bezier.new(pointA.Position, pointB.Position, pointC.Position)
    
    private.path = curve:GetPath(0.001)

    print("choseRandomPathForMovement:  have successful set a path for movement -> ", private.path)
end

function movementPrototype:moveToTarget()
    local private = movementPrivate[self]

    local delayTime = 0

    while true do
        local targetRootPart = _getTargetRootPart(private.target)
		if not targetRootPart then
			return warn("moveToTarget:  target does not exist.")
		end

		local distanceBetweenTarget = (private.target.Position - private.part.position).Magnitude
        if distanceBetweenTarget <= private.maxDistance then
            return warn("moveToTarget:  target has reached the max distance.")
        end

        if not next(private.path) then
            return print("moveToTarget:  there are not more values in path.")
        end

        private.part.Position = private.path[1]
        table.remove(private.path, 1)

        task.wait(delayTime)
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

function movementPrototype:reset()
    local private = movementPrivate[self]

    private.part.CFrame = CFrame.new(private.startPosition)
end

function movementPrototype:destroy()
    self:destroy()
end

movementPrototype.__index = movementPrototype
movement.__metatable = "This metatable is locked."
movement.__newindex = function(_, _, _)
    error("This metatable is locked.")
end

return movement