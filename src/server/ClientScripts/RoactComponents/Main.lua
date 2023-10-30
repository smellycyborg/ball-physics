local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Roact = require(Packages:WaitForChild("roact"))

local Main = Roact.Component:extend("Main")

function Main:init()
    self.onBlockButtonActivated = function(_rbx)
        self.props.blockAsTarget:Fire(workspace.CurrentCamera.CFrame)
    end
end

function Main:render()
    return Roact.createElement("ScreenGui", {
        ResetOnSpawn = false,
    }, {
        BlockButton = Roact.createElement("TextButton", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.9),
            Size = UDim2.fromScale(0.2, 0.2),
            Text = "block",
            [Roact.Event.Activated] = self.onBlockButtonActivated,
        })
    })
end

return Main