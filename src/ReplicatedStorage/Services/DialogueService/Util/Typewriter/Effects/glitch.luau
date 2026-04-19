-- Glitch effect. Clones the label twice (pink + cyan) and offsets them
-- by +/- 1px to fake chromatic aberration, then randomly flickers each
-- clone on for ~0.1s. Heavier than other effects (spawns 2 extra Guis
-- per character) so use sparingly.

local RunService = game:GetService("RunService")

return function(label: TextLabel, data: {Index : number})
	local originalPos = label.Position
	local originalColor = label.TextColor3
	
	local new1 = label:Clone()
	new1.Parent = label.Parent
	new1.TextColor3 = Color3.fromRGB(244, 85, 255)
	local new2 = label:Clone()
	new2.Parent = label.Parent
	new2.TextColor3 = Color3.fromRGB(84, 255, 255)
	
	--label.ZIndex+=1
	
	local last1, was1 = tick()
	local last2, was2 = tick()
	
	return RunService.RenderStepped:Connect(function()
		new1.Position = label.Position+UDim2.fromOffset(1,1)
		new2.Position = label.Position+UDim2.fromOffset(-1,-1)
		if tick()-last1 < 0.1 then
			new1.Visible = true
		else
			new1.Visible = false
		end
		if math.random()>0.95 and not was1 then
			was1 = true
			last1 = tick()
		else
			was1 = false
		end
		if tick()-last2 < 0.1 then
			new2.Visible = true
		else
			new2.Visible = false
		end
		if math.random()>0.95 and not was2 then
			was2 = true
			last2 = tick()
		else
			was2 = false
		end
	end)
end