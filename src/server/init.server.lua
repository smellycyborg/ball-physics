local Sdk = require(script.Sdk)

local START_POSITION = Vector3.new(0, 10, 0)
local MAX_DISTANCE = 5

local options = {
    startPosition = START_POSITION,
    maxDistance = MAX_DISTANCE,
}

Sdk.init(options)