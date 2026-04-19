local rs = game:GetService("ReplicatedStorage")
local Framework = require(rs:WaitForChild("Framework"))
Framework:WaitUntilLoaded()

local part = Framework.Utilities.DebugUtils.NewSphere(nil, {lifetime = -1})
local bezier = Framework.Utilities.Bezier

local positions = {Vector3.new(10,2,0), Vector3.new(15, 10, 10), Vector3.new(8, 3, 23), Vector3.new(22, 8, 34)}

workspace:WaitForChild("Labels"):WaitForChild("BezierLabel"):WaitForChild("Label").Parent = part

for _, pos in positions do
	Framework.Utilities.DebugUtils.NewSphere(pos, {lifetime = -1, color = Color3.new(1,0,0), size = 0.2})
end

Framework.Services.RunService.RenderStepped:Connect(function(dt)
	
	local curTime = math.sin(tick())/2+0.5
	local nextTime = curTime+dt
	
	local pos = bezier.GetSmoothSpline(curTime, positions)
	part.Position = pos
	
	if nextTime < 1 then
		Framework.Utilities.DebugUtils.NewLine(pos, bezier.GetSmoothSpline(nextTime, positions), {
			color = Color3.new(0,0,1),
			lifetime = 1,
		})
	end
	
end)