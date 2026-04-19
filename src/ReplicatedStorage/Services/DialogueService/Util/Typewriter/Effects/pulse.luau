-- Pulse effect. Adds a UIScale to the letter and drives its Scale on a
-- sine wave for a breathing/throbbing look. Per-letter offset keeps it
-- from looking like a single group scaling.

local RunService = game:GetService("RunService")

return function(label: TextLabel, data: {Index : number})
	local originalSize = label.Size
	local offset = data.Index * 0.5
	
	local uiScale = Instance.new("UIScale", label)

	return RunService.RenderStepped:Connect(function()
		local scale = 1 + (math.sin(tick() * 6 + offset) * 0.2)
		uiScale.Scale = scale
	end)
end