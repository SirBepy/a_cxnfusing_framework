local imagine = require(script:WaitForChild("Imagine"))

return function(obj : ImageLabel | ImageButton)
	if not obj then return end

	local Config = {
		
		XSpeed = obj:GetAttribute("XSpeed"),
		YSpeed = obj:GetAttribute("YSpeed"),
		
		XTileAmount = obj:GetAttribute("XTileAmount"),
		YTileAmount = obj:GetAttribute("YTileAmount"),
		
	}

	imagine.apply(obj):Animate(Config)

end