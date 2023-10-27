local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

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

local function characterAdded(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local attachment1 = Instance.new("Attachment", humanoidRootPart)
    attachment1.Name = "Attachment1"
end

local function playerAdded(player)
    mainMovement:addPlayerToMovementGroup(player)
    
    player.CharacterAdded:Connect(characterAdded)
end

local function playerRemoving(player)

end

local function onHeartbeat(step)

    if isTasking then
        return
    end

    isTasking = true



    isTasking = false

end

function Sdk.init(options)

    mainMovement = Movement.new(options.startingPosition, options.maxDistance)

    if IS_TESTING then
        task.delay(5, function()
            mainMovement:setTarget()
        end)
    end

    -- bindings
    RunService.Heartbeat:Connect(onHeartbeat)

    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)

end

return Sdk