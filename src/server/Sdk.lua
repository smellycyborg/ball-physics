local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Classes = script.Parent.Classes

local Movement = require(Classes.Movement)

local IS_TESTING = true

local isTasking = false

local Sdk = {}

local function _createTestGroup()
    testGroupFolder = Instance.new("Folder", workspace)
    testGroupFolder.Name = "TestGroup"

    local testGroupMemberA = Instance.new("Part", testGroupFolder)
    testGroupMemberA.Name = "TestGroupMemberA"
    testGroupMemberA.Anchored = true
    testGroupMemberA.CanCollide = false
    testGroupMemberA.CFrame = CFrame.new(Vector3.new(-142, 0.5, 37))

    local testGroupMemberB = Instance.new("Part", testGroupFolder)
    testGroupMemberB.Name = "TestGroupMemberA"
    testGroupMemberB.Anchored = true
    testGroupMemberB.CanCollide = false
    testGroupMemberB.CFrame = CFrame.new(Vector3.new(118, 0.5, 37))
end

local function onHeartbeat(step)

    if isTasking then
        return
    end

    isTasking = true



    isTasking = false

end

function Sdk.init(options)

    mainMovement = Movement.new(options.startPosition, options.maxDistance)

    if IS_TESTING then
        _createTestGroup()

        for _, testGroupMember in testGroupFolder:GetChildren() do
            mainMovement:addPlayerToMovementGroup(testGroupMember)
        end

        mainMovement:choseRandomTargetFromGroup()
        mainMovement:setMovementPath()
        mainMovement:moveToTarget()
    end



    -- bindings
    RunService.Heartbeat:Connect(onHeartbeat)

end

return Sdk