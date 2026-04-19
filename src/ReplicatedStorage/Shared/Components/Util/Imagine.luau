--[[
	Purpose:
		Scrolls a tiled ImageLabel/ImageButton's position each frame so the
		texture looks like it's flowing. Classic "conveyor belt" / "parallax
		clouds" / "scrolling background" trick.

	When to use:
		Animated UI backgrounds, loading-screen patterns, moving texture FX on
		GUIs. Anything where you want a tiled image to slide continuously
		without baking it into a video.

	Example:
		local anim = Imagine.apply(someImageLabel)
		anim:Animate({ XSpeed = 50, YSpeed = 0, XTileAmount = 3, YTileAmount = 3 })
		-- later:
		anim:Unapply()

	Gotchas:
		- Client-only: uses RenderStepped.
		- The ImageLabel must use TileSize (ScaleType = Tile) for the wrap math
		  to make sense.
		- Size gets overwritten to UDim2.fromScale(XTileAmount, YTileAmount)
		  because the wrap math relies on Size.X.Scale != 0.
		- Unapply nukes the metatable; don't reuse the object after calling it.
]]

local Imagine = {}
Imagine.__index = Imagine

local table = require(script.Parent:WaitForChild("ExtendedLibraries")).table

local DefaultConfig = {

	XSpeed = 100,
	YSpeed = 100,

	XTileAmount = 2,
	YTileAmount = 2,

}

type Image = typeof(Imagine)

function Imagine.apply(base : ImageLabel | ImageButton) : Image
	if not base then return end
	return setmetatable({Base = base}, Imagine)
end

function Imagine:Animate(
	Config : {

		XSpeed : number,
		YSpeed : number,

		XTileAmount : number,
		YTileAmount : number,

	})
	
	Config = table.clone(Config or DefaultConfig)
	Config = table.merge(DefaultConfig, Config)
	
	local Xoffset = 0
	local Yoffset = 0
	
	local image = self.Base

	image.Size = UDim2.fromScale(Config.XTileAmount, Config.YTileAmount)

	self.Connection = game["Run Service"].RenderStepped:Connect(function(dt)

		Xoffset += Config.XSpeed*dt
		Yoffset += Config.YSpeed*dt

		local absSize = image.AbsoluteSize
		local tileSize = image.TileSize

		local frameSizeX = absSize.X/image.Size.X.Scale
		local frameSizeY = absSize.Y/image.Size.Y.Scale

		-- Snap the wrap-around point to the nearest whole tile boundary. Reset
		-- once the scroll distance exceeds that boundary so the pattern jumps
		-- back by exactly N tiles, hiding the reset (the image looks identical
		-- at every tile boundary, so the viewer never sees the snap).
		local closestPointX =
			math.floor((absSize.X-frameSizeX)/tileSize.X.Offset)
			* tileSize.X.Offset
		local closestPointY =
			math.floor((absSize.Y-frameSizeY)/tileSize.Y.Offset)
			* tileSize.Y.Offset

		if math.abs(Xoffset) > closestPointX then
			Xoffset = 0
		end
		if math.abs(Yoffset) > closestPointY then
			Yoffset = 0
		end

		image.Position = UDim2.new(0,-Xoffset,0,-Yoffset)

	end)

end

function Imagine:Unapply()
	for i, v in self do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		end
		self[i] = nil
	end
	setmetatable(self, nil)
end

return Imagine