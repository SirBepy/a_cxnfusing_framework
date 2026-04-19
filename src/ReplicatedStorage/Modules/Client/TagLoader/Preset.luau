--[[
	Preset (TagLoader child)

	Purpose:
		Lets designers set a single `Preset` attribute on an instance and
		have a bundle of attributes copied onto it from a preset template
		in the `Presets` folder inside this module.

	When to use:
		Tag any instance with "Preset" and give it a string attribute
		`Preset = "SomeName"`. A matching child Instance under `Presets`
		(its attributes are the template) expands onto the target. Author
		one preset, reuse it on hundreds of instances.

	Example:
		-- Presets/BigButton has attributes: HoverSize=1.2, HoverRotation=10
		-- On a Frame in game: add tag "Preset", set attribute Preset="BigButton"
		-- After load: Frame has HoverSize=1.2 and HoverRotation=10.

	Gotchas:
		- Runs ONCE per instance (TagLoader init is one-shot), then the
		  `Preset` attribute is cleared so it can't re-apply or loop.
		- Existing attributes WIN: if the target already has `HoverSize`
		  set, the preset's value is skipped. Lets you override per-instance.
		- Presets folder missing or preset not found = silent no-op.
		- Preset load order matters: TagLoader runs Preset first so other
		  tag modules see the expanded attributes, not the raw `Preset` key.
]]

local presetFolder = script:WaitForChild("Presets")

local function grabPreset(name : string)
	if not name then return end

	local f = presetFolder:FindFirstChild(name)
	return f

end

local function check(obj : Instance)

	local preset = obj:GetAttribute("Preset")
	if preset then
		-- `atts` is a preset Instance first (holds attributes as its template),
		-- then gets reassigned to the actual attribute table. Rough but works.
		local atts : {[string] : any} = grabPreset(preset)
		if not atts then return end
		atts = atts:GetAttributes()
		for att, val in pairs(atts) do
			-- Don't clobber per-instance overrides already set by the designer.
			if obj:GetAttribute(att) ~= nil then continue end
			obj:SetAttribute(att, val)
		end
	end
	-- Clear so later tag modules (or re-tagging) don't re-trigger expansion
	-- and so the attribute list stays clean in Studio.
	obj:SetAttribute("Preset", nil)

end

return check