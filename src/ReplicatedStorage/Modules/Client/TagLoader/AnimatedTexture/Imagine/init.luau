--[[
	Imagine

	Purpose:
		Internal engine behind AnimatedTexture. Wraps a tiled image and
		advances its Position each frame so the texture appears to scroll.

	When to use:
		Called by `AnimatedTexture/init.luau`. You typically don't use this
		directly, but you can:
			local img = Imagine.apply(someImageLabel)
			img:Animate({XSpeed = 60, YSpeed = 0})
			-- later
			img:Unapply()

	Example:
		Imagine.apply(myImage):Animate({XSpeed = 50, YSpeed = 50,
			XTileAmount = 8, YTileAmount = 8})

	Gotchas:
		- The local name `table` shadows Luau's global `table` for this file
		  on purpose (gives us `merge`/`clone`); don't touch it expecting
		  stdlib behavior. Review flagged this as hostile; kept for now.
		- `Imagine.apply(nil)` returns nil silently; callers must guard.
		- Sizes the image to `UDim2.fromScale(XTileAmount, YTileAmount)`,
		  which means the ImageLabel will be that many parent-sizes wide/tall.
		  Expected to be clipped by a parent frame.
		- `:Unapply` iterates `self` while clearing it; works today because
		  the first loop disconnects, but fragile.
]]

local Imagine = {}
Imagine.__index = Imagine

-- NOTE: intentional shadow of the stdlib `table`. TableExtended falls back
-- to the real `table` via metatable __index, so `table.clone`, `table.insert`,
-- etc. still work, plus we gain `table.merge`.
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
	
	-- Clone first so we never mutate the caller's table, then merge over
	-- defaults so any nil field (unset attribute) falls back cleanly.
	Config = table.clone(Config or DefaultConfig)
	Config = table.merge(DefaultConfig, Config)
	
	local Xoffset = 0
	local Yoffset = 0
	
	local image = self.Base

	-- Blow the image up so there's always enough tiled surface to scroll
	-- under the parent's clip region without seeing an edge.
	image.Size = UDim2.fromScale(Config.XTileAmount, Config.YTileAmount)

	-- `game["Run Service"]` works because Roblox services accept spaced names
	-- via indexing; prefer `GetService("RunService")` in new code.
	self.Connection = game["Run Service"].RenderStepped:Connect(function(dt)
		Xoffset += Config.XSpeed * dt
		Yoffset += Config.YSpeed * dt

		local absSize = image.AbsoluteSize
		local tileSize = image.TileSize

		local wrapX = tileSize.X.Offset
		local wrapY = tileSize.Y.Offset

		-- Modulo by tile size so the offset resets every tile; creates an
		-- infinite-scroll illusion without the number growing forever.
		local loopedX = Xoffset % wrapX
		local loopedY = Yoffset % wrapY

		-- Negative position so the texture appears to move in +X/+Y
		-- (we slide the image itself the other way).
		image.Position = UDim2.new(0, -loopedX, 0, -loopedY)
	end)

end

function Imagine:Unapply()
	-- Walk every field: disconnect any RBXScriptConnections, nil out the
	-- rest. Done in one loop to keep teardown simple even if more
	-- connections get added later.
	for i, v in self do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		end
		self[i] = nil
	end
	-- Drop the metatable so lingering references to this instance stop
	-- resolving the :Animate / :Unapply methods.
	setmetatable(self, nil)
end

return Imagine