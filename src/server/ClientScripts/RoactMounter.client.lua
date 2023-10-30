local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local RoactComponents = script.Parent.RoactComponents

local Comm = require(Packages:WaitForChild("comm"))
local Roact = require(Packages:WaitForChild("roact"))
local Main = require(RoactComponents.Main)

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "Comm")
local blockAsTarget = clientComm:GetSignal("BlockAsTarget")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local handle = Roact.mount(Roact.createElement(Main, {
    blockAsTarget = blockAsTarget,
}), playerGui, "Main")

local function updateHandle()
    Roact.updte(handle, Roact.createElement(Main, {
        blockAsTarget = blockAsTarget,
    }), playerGui, "Main")
end