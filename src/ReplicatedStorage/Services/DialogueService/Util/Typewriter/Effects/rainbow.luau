local RunService = game:GetService("RunService")

local length = 10

return function(label: TextLabel, data : {Index : number})
	local connection = RunService.RenderStepped:Connect(function()
		label.TextColor3 = Color3.fromHSV((tick()+data.Index*0.2) % length/length, 1, 1)
	end)

	return connection
end