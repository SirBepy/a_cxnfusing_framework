--[[
	AnimatedTexture (TagLoader child)

	Purpose:
		Scrolls a tiled ImageLabel/ImageButton texture every frame to fake
		an animated background (conveyor belts, scrolling skies, parallax
		patterns).

	When to use:
		Add the "AnimatedTexture" tag to an ImageLabel/ImageButton whose
		`ScaleType` is `Tile`. Set attributes to tweak:
			XSpeed, YSpeed             - scroll speed in offset units/sec
			XTileAmount, YTileAmount   - how many tiles to cover (via scale)

		Unset attributes fall back to `Imagine`'s DefaultConfig.

	Example:
		-- ImageLabel with ScaleType=Tile, TileSize=UDim2.fromOffset(64,64),
		-- tagged "AnimatedTexture", attribute XSpeed=80 -> scrolls right.

	Gotchas:
		- Filename "AnimatedTexture" == CollectionService tag.
		- No teardown: the RenderStepped connection inside Imagine lives
		  until the instance is destroyed. `Imagine:Unapply` exists but
		  nothing wires it up here.
		- Expects Tile scaling; other ScaleTypes won't scroll usefully.
		- `Imagine.apply(nil)` returns nil, but we early-return above it,
		  so this wrapper is safe.
]]

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