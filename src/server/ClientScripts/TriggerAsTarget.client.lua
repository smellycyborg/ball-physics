local ReplicatedStorage = game:GetServcie("ReplicatedStorage")
local UserInputService = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetServcie("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Comm = require(Packages:WaitForChild("comm"))

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "Comm")
local triggerAsTarget = Comm:GetSignal("TriggerAsTarget")

local function onAction()
    triggerAsTarget:Fire(workspace.CurrentCamera.CFrame)
end