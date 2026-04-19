--[[
	FastTween.

	Purpose:
		One-liner wrapper around TweenService. Takes an instance, a compact
		TweenInfo-like array (or nil for defaults), and a goals table. Builds
		the TweenInfo, creates the tween, plays it, and hands it back.

	When to use:
		Whenever you'd normally write three lines of TweenService boilerplate
		for a quick UI fade, part move, color flash, etc. Keep real TweenInfo
		usage for anything complex (RepeatCount, Reverses, DelayTime chains).

	Example:
		-- Simplest call: just goals, uses defaults (1s, Sine, InOut)
		FastTween(frame, nil, { BackgroundTransparency = 1 })

		-- With style options as a positional array:
		-- { time, easingStyle, easingDirection, repeatCount, reverses }
		FastTween(part, {0.5, "Quad", "Out"}, { Position = target })

		-- Strings get looked up on the Enum automatically, so you can pass
		-- either Enum.EasingStyle.Quad or just "Quad". Same for direction.
		FastTween(gui, {2, Enum.EasingStyle.Back, "InOut"}, { Size = UDim2.fromScale(1,1) })

	Gotchas:
		- Passing nil for tweenInfo works, but passing an empty {} is safer
		  if you want explicit "use defaults".
		- Returns the Tween so you can :Connect to Completed if you need it.
		- Silent bail on missing obj/goals - no error, no warn. Check your
		  args yourself if you need to know it ran.
]]

-- Fallback values applied whenever a slot in the user's tweenInfo array is nil.
-- Order matches TweenInfo.new: time, style, direction, repeatCount, reverses.
local defaultTI = {
	1,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	0,
	false,
}

local ts = game:GetService("TweenService")

return function(obj : Instance, tweenInfo : {}, goals : {[string] : any}) : Tween
	if not obj or not goals then return end

	-- Clone so we don't mutate the caller's table when filling in defaults.
	tweenInfo = table.clone(tweenInfo) or defaultTI

	-- Fill any missing slots from defaults so shorthand calls like
	-- FastTween(x, {0.25}, goals) still produce a valid TweenInfo.
	for i, value in defaultTI do
		if not tweenInfo[i] then
			tweenInfo[i] = value
		end
	end

	-- Let callers pass enum names as strings ("Quad" instead of Enum.EasingStyle.Quad)
	-- so quick-and-dirty tween calls read cleaner.
	if type(tweenInfo[2]) == "string" then
		tweenInfo[2] = Enum.EasingStyle[tweenInfo[2]]
	end
	if type(tweenInfo[3]) == "string" then
		tweenInfo[3] = Enum.EasingStyle[tweenInfo[3]]
	end

	local ti = TweenInfo.new(tweenInfo[1], tweenInfo[2], tweenInfo[3], tweenInfo[4], tweenInfo[5])
	local tween = ts:Create(obj, ti, goals)

	tween:Play()

	return tween
end
