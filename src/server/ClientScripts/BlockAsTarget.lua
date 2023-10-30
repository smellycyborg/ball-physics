local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Comm = require(Packages:WaitForChild("comm"))

local clientComm = Comm.ClientComm.new(ReplicatedStorage, false, "Comm")
local blockAsTarget = clientComm:GetSignal("BlockAsTarget")

local ContextActionService = game:GetService("ContextActionService")

local F_KEY = Enum.KeyCode.F
local RIGHT_TRIGGER_XBOX = Enum.KeyCode.ButtonR2

local function actionHandler(actionName, inputState, inputObject)
    if inputState == Enum.UserInputState.Begin then
        blockAsTarget:Fire(workspace.CurrentCamera.CFrame)
    end
end

ContextActionService:BindAction(
    "Block", 
    actionHandler, 
    false, 
    RIGHT_TRIGGER_XBOX, F_KEY
)
