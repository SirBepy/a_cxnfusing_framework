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
		target = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", obj)
	elseif typeName == "Raise" then
		local originalPos = obj:GetAttribute("OriginalPosition")
		finalGoal = originalPos - UDim2.fromOffset(0, goalValue)
	end

	local ti = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Sine, dir or Enum.EasingDirection.Out)
	ts:Create(target, ti, {[propertyName] = finalGoal}):Play()
end

function UIAnimation.init(obj: GuiObject)
	if not obj:GetAttribute("OriginalPosition") then obj:SetAttribute("OriginalPosition", obj.Position) end
	if not obj:GetAttribute("OriginalBGColor")  then obj:SetAttribute("OriginalBGColor", obj.BackgroundColor3) end
	if not obj:GetAttribute("OriginalRotation") then obj:SetAttribute("OriginalRotation", obj.Rotation) end

	local function getResetValue(typeName)
		if typeName == "Size" then return 1 end
		if typeName == nil or typeName == "Raise" then return 0 end
		return obj:GetAttribute("Original" .. typeName)
	end

	local function handleInput(isEnter)
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
					config.Value = obj:GetAttribute("Original"..attrName)
				end

				applyTween(obj, typeName, config.Value, config.Click, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

				task.delay(config.Click, function()
					local resetVal = getResetValue(typeName)
					applyTween(obj, typeName, resetVal, config.Return, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				end)
			end

			task.wait(0.3)
			obj:SetAttribute("_clicked", nil)
		end)
	end
end

return UIAnimation.init