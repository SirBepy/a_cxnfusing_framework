-- Wobble effect. Each letter orbits its spawn position on a Lissajous
-- pattern (sin on X, cos on Y at different speeds). The per-letter Index
-- offset keeps adjacent characters out of phase so the text looks drunk
-- instead of bouncing in sync.
-- Returns the RenderStepped connection so the Typewriter can disconnect
-- it on :Destroy.

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