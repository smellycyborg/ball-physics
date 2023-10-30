local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Comm = require(Packages:WaitForChild("comm"))

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "Comm")
local triggerAsTarget = clientComm:GetSignal("TriggerAsTarget")

local ContextActionService = game:GetService("ContextActionService")

local function actionHandler(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        triggerAsTarget:Fire(workspace.CurrentCamera.CFrame)
    end
end

ContextActionService:BindAction("Block", actionHandler, false, Enum.KeyCode.ButtonA, Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1)
