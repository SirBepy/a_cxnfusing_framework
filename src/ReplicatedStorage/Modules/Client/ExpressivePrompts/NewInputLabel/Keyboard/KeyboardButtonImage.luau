--[[
	KeyboardButtonImage
	-------------------
	Purpose:
		Maps Enum.KeyCode values to built-in glyph assets for the few keys
		that are best shown as an icon rather than text (Backspace, Return,
		Shift, Tab).

	When to use:
		Primary lookup used by Keyboard/init.luau. Add entries here for any
		KeyCode you want to render as an icon.

	Gotchas:
		- Both LeftShift and RightShift point at the same asset - intentional.
		- This is the KeyCode-keyed table. For printable-character keys (like
		  spacebar or comma) use KeyboardButtonIconMapping.luau instead.
]]

return {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}