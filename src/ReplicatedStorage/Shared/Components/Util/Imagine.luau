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