local Imagine = {}
Imagine.__index = Imagine

local table = require(script:WaitForChild("TableExtended"))

local DefaultConfig = {

	XSpeed = 100,
	YSpeed = 100,

	XTileAmount = 10,
	YTileAmount = 10,

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
		Xoffset += Config.XSpeed * dt
		Yoffset += Config.YSpeed * dt

		local absSize = image.AbsoluteSize
		local tileSize = image.TileSize

		local wrapX = tileSize.X.Offset
		local wrapY = tileSize.Y.Offset

		local loopedX = Xoffset % wrapX
		local loopedY = Yoffset % wrapY

		image.Position = UDim2.new(0, -loopedX, 0, -loopedY)
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