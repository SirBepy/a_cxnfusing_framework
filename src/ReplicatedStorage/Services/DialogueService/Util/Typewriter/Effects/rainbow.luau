-- Rainbow effect. Cycles TextColor3 through HSV hues over time. `length`
-- is the cycle period in seconds; each letter is phase-shifted by its
-- Index so the colour travels across the word.

local RunService = game:GetService("RunService")

local length = 10

return function(label: TextLabel, data : {Index : number})
	local connection = RunService.RenderStepped:Connect(function()
		label.TextColor3 = Color3.fromHSV((tick()+data.Index*0.2) % length/length, 1, 1)
	end)

	return connection
end