local RunService = game:GetService("RunService")

return function(label: TextLabel, data: {Index : number})
	local originalPos = label.Position
	local offset = data.Index * 0.3 

	return RunService.RenderStepped:Connect(function()
		local y = math.sin(tick() * 5 + offset) * 4
		label.Position = originalPos + UDim2.fromOffset(0, y)
	end)
end