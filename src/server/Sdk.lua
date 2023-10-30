local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Classes = script.Parent.Classes
local Packages = ReplicatedStorage.Packages

local Movement = require(Classes.Movement)

local Comm = require(Packages.comm)

local IS_TESTING = true

local serverComm = Comm.ServerComm.new(ReplicatedStorage, "Comm")

local isTasking = false

local Sdk = {
    hasBlocked = {},
}

local function _createTestGroup()
    testGroupFolder = Instance.new("Folder", workspace)
    testGroupFolder.Name = "TestGroup"

    local testGroupMemberA = Instance.new("Part", testGroupFolder)
    testGroupMemberA.BrickColor = BrickColor.Random()
    testGroupMemberA.Size = Vector3.new(5, 5, 5)
    testGroupMemberA.Name = "TestGroupMemberA"
    testGroupMemberA.Anchored = true
    testGroupMemberA.CanCollide = false
    testGroupMemberA.CFrame = CFrame.new(Vector3.new(-142, 7, 37))

    local testGroupMemberB = Instance.new("Part", testGroupFolder)
    testGroupMemberB.BrickColor = BrickColor.Random()
    testGroupMemberB.Size = Vector3.new(5, 5, 5)
    testGroupMemberB.Name = "TestGroupMemberA"
    testGroupMemberB.Anchored = true
    testGroupMemberB.CanCollide = false
    testGroupMemberB.CFrame = CFrame.new(Vector3.new(118, 7, 37))
end

local function _setCanTouch(character)
    local player = Players:GetPlayerFromCharacter(character)

    local hasLoaded = character:FindFirstChild("HumanoidRootPart") or player.CharacterAppearanceLoaded:Wait()

    for _, part in character:GetChildren() do
        if part:IsA("BasePart") or part:IsA("Part") and part.Name ~= "HumanoidRootPart" then
            part.CanTouch = false
        end
    end
end

local function _setHitbox(character, isPlayer)
    if isPlayer then
        local player = Players:GetPlayerFromCharacter(character)

        local hasLoaded = character:FindFirstChild("HumanoidRootPart") or player.CharacterAppearanceLoaded:Wait()
    end

    local hitbox = Instance.new("Part")
    hitbox.Name = isPlayer and "Hitbox" or "HitboxTest"
    hitbox.CFrame = not isPlayer and CFrame.new(character.Position) or CFrame.new(character:FindFirstChild("HumanoidRootPart").Position)
    hitbox.Size = Vector3.new(4, 8, 4)
    hitbox.Massless = true
    hitbox.CanCollide = false
    hitbox.Transparency = 1
    hitbox.BrickColor = BrickColor.Random()
    hitbox.Parent = character

    local weld = Instance.new("Weld", hitbox)
    weld.Part0 = hitbox
    weld.Part1 = isPlayer and character:FindFirstChild("HumanoidRootPart") or character
end

local function characterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)

    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    _setHitbox(character, true)
    
    local foundPlayerInGroup = mainMovement:isPlayerInMovementGroup(player)
    if not foundPlayerInGroup then
        mainMovement:addPlayerToMovementGroup(player)
    end
end

local function playerAdded(player)
    mainMovement:addPlayerToMovementGroup(player)

    if player.Character then
        characterAdded(player.Character)

        return
    end
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

    -- clone client scripts to start player scripts
	local ClientScripts = script.Parent.ClientScripts
	local clientScriptsClone = ClientScripts:Clone()
	clientScriptsClone.Name = "ClientScripts"
	clientScriptsClone.Parent = StarterPlayer:WaitForChild("StarterPlayerScripts")

    local blockAsTarget = serverComm:CreateSignal("BlockAsTarget")

    mainMovement = Movement.new(
        options.startingPosition, 
        options.maxDistance,
        options.timeUntilNextTarget,
        options.startSpeed,
        options.maxSpeed,
        options.distanceToBlock
    )

    mainMovement.killPlayer:Connect(function(player)
        if not player then
            return
        end

        mainMovement:removePlayerFromMovementGroup(player)
        local character = player.Character
        if not character then
            return
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then
            return
        end

        humanoid.Health -= 1000
    end)

    print("Started movement.")

    if IS_TESTING then
        _createTestGroup()

        for _, groupMember in testGroupFolder:GetChildren() do 
            mainMovement:addPlayerToMovementGroup(groupMember)
            _setHitbox(groupMember, false)
        end


        task.delay(10, function()
           mainMovement:startMovement()
        end)
    end

    -- bindings
    -- RunService.Heartbeat:Connect(onHeartbeat)

    Players.PlayerAdded:Connect(playerAdded)
    Players.PlayerRemoving:Connect(playerRemoving)

    blockAsTarget:Connect(function(player, cameraCFrame)
        local hasBlocked = table.find(Sdk.hasBlocked, player)
        if hasBlocked then
            return
        end

        table.insert(Sdk.hasBlocked, player)

        task.delay(0.5, function()
            table.remove(Sdk.hasBlocked, table.find(Sdk.hasBlocked, player))
        end)

        local targetPlayer = mainMovement:getTargetPlayer()
        if targetPlayer ~= player then
            return
        end

        local canBlock = mainMovement:canTargetPlayerBlock()
        if canBlock then
            mainMovement:setBlocked()
            mainMovement:setTarget(player, cameraCFrame)
        end
    end)

end

return Sdk