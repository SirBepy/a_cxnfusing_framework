local RunService = game:GetService("RunService")
local Shared = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"))

return function(label: TextLabel, data : {Index : number})
	local originalPos = label.Position
	local randomOffset = 0.05 * (data.Index or 1) -- Offset so they don't all move in sync

	local screenSize = workspace.CurrentCamera.ViewportSize
	local div = 500
	
	local connection = RunService.RenderStepped:Connect(function()
		local t = tick() + randomOffset
		local x = math.sin(t * 10) * screenSize.X/div
		local y = math.cos(t * 12) * screenSize.Y/div
		
		local new = originalPos + UDim2.fromOffset(x, y)
		label.Position = new
		
	end)

	return connection
end