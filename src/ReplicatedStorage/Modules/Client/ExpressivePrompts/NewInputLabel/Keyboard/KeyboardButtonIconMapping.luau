--[[
	KeyboardButtonIconMapping
	-------------------------
	Purpose:
		Maps printable characters (as returned by UIS:GetStringForKeyCode) to
		shipped Roblox glyph assets for keys that are awkward to render as
		text (apostrophe, comma, backtick, period, spacebar).

	When to use:
		Secondary lookup used by Keyboard/init.luau when the primary keycode
		lookup misses. Add entries here for printable-char keys that would
		otherwise render as a weirdly small TextLabel.

	Gotchas:
		- Keys here are the character strings, NOT Enum.KeyCode values. Check
		  KeyboardButtonImage.luau for the KeyCode-keyed table.
]]

return {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}