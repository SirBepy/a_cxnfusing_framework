--[[
	UIAnimate (TagLoader child)

	Purpose:
		Attribute-driven hover / click animations for GuiObjects. Scale,
		rotate, recolor, and "raise" (upward offset) tweens on MouseEnter /
		MouseLeave / MouseButton1Click, with per-animation tuning via
		attributes.

	When to use:
		Add the "UIAnimate" tag to any GuiObject. Set any of these
		attributes to opt into an effect (all optional):
			HoverSize, ClickSize         (numbers, 1 = no change)
			HoverRotation, ClickRotation (degrees)
			HoverBGColor, ClickBGColor   (Color3)
			HoverRaise, ClickRaise       (studs on Y, positive = up)

		Fine-tune timings per attribute with `_EnterLength`,
		`_LeaveLength`, `_ClickLength`, `_ReturnLength` suffixes, e.g.
		`HoverSize_EnterLength = 0.3`.

	Example:
		-- A TextButton tagged "UIAnimate" with:
		--   HoverSize = 1.15, ClickSize = 0.9, HoverRaise = 4
		-- bounces a little on hover + dips on click.

	Gotchas:
		- Filename "UIAnimate" == CollectionService tag (TagLoader contract).
		- Stores bookkeeping on the instance as attributes: `OriginalPosition`,
		  `OriginalBGColor`, `OriginalRotation`, `_clicked`. Noted as attribute
		  pollution in the review; fine for the demo, swap to a weak table
		  later.
		- Uses `Instance.new("UIScale", obj)` (deprecated parent-in-ctor form).
		- No disconnect: MouseEnter/Leave/Click connections live until the
		  GuiObject is destroyed; fine for UI that persists, leaky if you
		  recreate lots of GuiObjects.
		- `task.wait(0.3)` click cooldown is hard-coded, not derived from
		  `Click + Return` lengths.
]]

local ts = game:GetService("TweenService")

local UIAnimation = {}

local defaults = {

	HoverSize = 1.1,
	ClickSize = 0.9,

	HoverRotation = 5,
	ClickRotation = 15,

	HoverBGColor = Color3.fromRGB(45, 45, 45),
	ClickBGColor = Color3.fromRGB(0, 0, 0),

	HoverRaise = 5,
	ClickRaise = -2,

}

local props = {
	Size = "Scale",
	Rotation = "Rotation",
	BGColor = "BackgroundColor3",
	Raise = "Position" 
}

local types = {"Size", "Rotation", "BGColor", "Raise"}

local function getConfig(obj, baseName)
	return {
		Value = obj:GetAttribute(baseName) or defaults[baseName],
		Enter = obj:GetAttribute(baseName.."_EnterLength") or 0.2,
		Leave = obj:GetAttribute(baseName.."_LeaveLength") or 0.2,
		Click = obj:GetAttribute(baseName.."_ClickLength") or 0.1,
		Return = obj:GetAttribute(baseName.."_ReturnLength") or 0.15,
	}
end

local function applyTween(obj, typeName, goalValue, duration, style, dir)
	local target = obj
	local propertyName = props[typeName]
	local finalGoal = goalValue

	if typeName == "Size" then
		-- Scale via a UIScale child instead of tweening `Size` itself, so
		-- layout / anchoring stays intact and we don't fight UIListLayout.
		target = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", obj)
	elseif typeName == "Raise" then
		-- Raise = offset upward from the cached original position so
		-- repeated hovers don't drift (tweening relative would stack).
		local originalPos = obj:GetAttribute("OriginalPosition")
		finalGoal = originalPos - UDim2.fromOffset(0, goalValue)
	end

	local ti = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out)
	ts:Create(target, ti, {[propertyName] = finalGoal}):Play()
end

function UIAnimation.init(obj: GuiObject)
	-- Snapshot the "resting" state once so Leave tweens know where to return
	-- to, even after many hovers/clicks. Guarded so re-init is idempotent.
	if not obj:GetAttribute("OriginalPosition") then obj:SetAttribute("OriginalPosition", obj.Position) end
	if not obj:GetAttribute("OriginalBGColor")  then obj:SetAttribute("OriginalBGColor", obj.BackgroundColor3) end
	if not obj:GetAttribute("OriginalRotation") then obj:SetAttribute("OriginalRotation", obj.Rotation) end

	local function getResetValue(typeName)
		if typeName == "Size" then return 1 end
		if typeName == nil or typeName == "Raise" then return 0 end
		return obj:GetAttribute("Original" .. typeName)
	end

	local function handleInput(isEnter)
		-- Skip hover tweens while a click animation is mid-flight, otherwise
		-- MouseLeave firing during the click sequence fights the click tween.
		if obj:GetAttribute("_clicked") then return end

		for _, typeName in types do
			local attrName = "Hover" .. typeName
			if obj:GetAttribute(attrName) ~= nil then
				local config = getConfig(obj, attrName)
				local val = isEnter and config.Value or getResetValue(typeName)
				applyTween(obj, typeName, val, isEnter and config.Enter or config.Leave)
			end
		end
	end

	obj.MouseEnter:Connect(function() handleInput(true) end)
	obj.MouseLeave:Connect(function() handleInput(false) end)

	if obj:IsA("GuiButton") then
		obj.MouseButton1Click:Connect(function()
			if obj:GetAttribute("_clicked") then return end
			obj:SetAttribute("_clicked", true)

			for _, typeName in types do
				local attrName = "Click" .. typeName
				local config = getConfig(obj, attrName)
				if obj:GetAttribute(attrName) == nil then
					-- No Click* attribute set: fall back to the Original*
					-- value so the "tween to click pose" is a no-op instead
					-- of snapping to the default constant.
					config.Value = obj:GetAttribute("Original"..attrName)
				end

				-- Exponential-In for the press (snappy attack), then...
				applyTween(obj, typeName, config.Value, config.Click, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

				task.delay(config.Click, function()
					-- ...Back-Out for the return, for that classic overshoot
					-- "bounce back" feel after release.
					local resetVal = getResetValue(typeName)
					applyTween(obj, typeName, resetVal, config.Return, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end)
			end

			-- Cooldown before another click is accepted. 0.3 is a rough
			-- "long enough for most Click+Return pairs" fudge; not derived.
			task.wait(0.3)
			obj:SetAttribute("_clicked", nil)
		end)
	end
end

return UIAnimation.init