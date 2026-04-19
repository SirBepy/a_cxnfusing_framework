local FlashController = {}

local presets = {

}
::
{
	[string] : {}
}

---<>--- Variables ---<>---

local flashLightingEffect = Instance.new("ColorCorrectionEffect", game:WaitForChild("Lighting"))
flashLightingEffect.Brightness = 1
flashLightingEffect.Enabled = false
flashLightingEffect.Name = "FlashEffect"

local rs = game:GetService("ReplicatedStorage")
local fastTween = require(script.Parent.Parent:WaitForChild("Functions")).FastTween

local table = require(script.Parent:WaitForChild("ExtendedLibraries")).table

---<>--- Helper Functions ---<>---

local function newHighlight(config : {})

	local set = table.merge({
		FillTransparency = 0,
		OutlineTransparency = 1,

		FlashTime = 0.1,
		FadeOut = 0.05,

		FillColor = Color3.new(1,1,1),
		OutlineColor = Color3.new(1,0,0),
		
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
	}, config or {})
	if not config.Object then return end

	local new = Instance.new("Highlight", set.Object)
	new.DepthMode = set.DepthMode
	
	new.FillTransparency = set.FillTransparency
	new.OutlineTransparency = set.OutlineTransparency

	new.FillColor = set.FillColor
	new.OutlineColor = set.OutlineColor

	task.delay(set.FlashTime, function()
		if set.FadeOut > 0 then
			fastTween(
				new,
				{set.FadeOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out},
				{FillTransparency = 1, OutlineTransparency = 1}
			)
			task.wait(set.FadeOut)
			new:Destroy()
		else
			new:Destroy()
		end
	end)

	return new
end

local function flashLighting(config : {})

	local set = table.merge({
		FlashTime = 0.1,
		FadeOut = 0.05,

		Color = Color3.new(0,0,0)
	}, config or {})

	flashLightingEffect.TintColor = set.Color
	flashLightingEffect.Enabled = true

	if set.Color.R+set.Color.G+set.Color.B == 0 then
		flashLightingEffect.Brightness = -1
	else
		flashLightingEffect.Brightness = 1
	end

	task.delay(set.FlashTime, function()
		if set.FadeOut > 0 then
			fastTween(
				flashLightingEffect,
				{set.FadeOut, Enum.EasingStyle.Sine, Enum.EasingDirection.Out},
				{Brightness = 0, TintColor = Color3.new(1,1,1)}
			)
		else
			flashLightingEffect.Enabled = false
		end
	end)

end

---<>--- Main Functions ---<>---

function FlashController:Flash(config : {

	Object : Instance,
	Lighting : boolean,

	Preset : string,

	HighlightConfig : {		
		FillTransparency : number,
		OutlineTransparency : number,

		FillColor : Color3,
		OutlineColor : Color3,

		FlashTime : number,
		FadeOut : number,
		
		DepthMode : Enum.HighlightDepthMode,
	},
	LightingConfig : {
		FlashTime : number,
		FadeOut : number,

		Color : Color3,
	}

	}) : Highlight?
	config = config or {}
	local preset = config.Preset and presets[config.Preset]
	local set = preset and table.merge(preset, config) or table.merge({
		Lighting = true,
	}, config)
	if not set.Object and not set.Lighting then return end

	if set.Lighting then
		flashLighting(set.LightingConfig)
	end
	if set.Object then
		set.HighlightConfig.Object = set.Object
		return newHighlight(set.HighlightConfig)
	end

end

return FlashController