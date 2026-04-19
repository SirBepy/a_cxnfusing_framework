local rs = game:GetService("ReplicatedStorage")
local Framework = require(rs:WaitForChild("Framework"))
Framework:WaitUntilLoaded()

local part = workspace:WaitForChild("ViewCheck")

while task.wait(0.05) do
	local vis = Framework.Utilities.ViewCheck.IsVisible(part.Position, {part})
	part.Color = vis and Color3.new(0,1,0) or Color3.new(1,0,0)
end