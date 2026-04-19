local presetFolder = script:WaitForChild("Presets")

local function grabPreset(name : string)
	if not name then return end
	
	local f = presetFolder:FindFirstChild(name)
	return f
	
end

local function check(obj : Instance)
	
	local preset = obj:GetAttribute("Preset")
	if preset then
		local atts : {[string] : any} = grabPreset(preset)
		if not atts then return end
		atts = atts:GetAttributes()
		for att, val in pairs(atts) do
			if obj:GetAttribute(att) ~= nil then continue end
			obj:SetAttribute(att, val)
		end
	end
	obj:SetAttribute("Preset", nil)
	
end

return check