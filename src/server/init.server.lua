local Sdk = require(script.Sdk)

local START_POSITION = Vector3.new(0, 10, 0)

local options = {
    startPosition = START_POSITION,
}

Sdk.init(options)