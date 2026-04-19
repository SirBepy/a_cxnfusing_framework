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
	
	tweenInfo = table.clone(tweenInfo) or defaultTI
	
	for i, value in defaultTI do
		if not tweenInfo[i] then
			tweenInfo[i] = value
		end
	end
	
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