local Sdk = require(script.Sdk)

local START_POSITION = Vector3.new(0, 10, 0)

local MAX_DISTANCE = 6
local START_SPEED = 25
local MAX_SPEED = 450
local TIME_UNTIL_NEXT_TARGET = 2.5
local DISTANCE_TO_BLOCK = 12

local options = {
    startingPosition = START_POSITION,
    maxDistance = MAX_DISTANCE,
    timeUntilNextTarget = TIME_UNTIL_NEXT_TARGET,
    startSpeed = START_SPEED,
    maxSpeed = MAX_SPEED,
    distanceToBlock = DISTANCE_TO_BLOCK,
}

Sdk.init(options)