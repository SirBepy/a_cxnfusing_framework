local RunService = game:GetService("RunService")

return function(label: TextLabel, data: {Index : number})
	local offset = data.Index * 0.4

	return RunService.RenderStepped:Connect(function()
		local alpha = (math.sin(tick() * 3 + offset) + 1) / 2
		label.TextTransparency = alpha * 0.8
	end)
end