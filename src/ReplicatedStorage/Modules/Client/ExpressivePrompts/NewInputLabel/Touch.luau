--[[
	Touch input label
	-----------------
	Purpose:
		Returns a single ImageLabel showing Roblox's built-in tap icon so
		touch users see "tap here" inside the prompt card.

	When to use:
		Internal - selected by NewInputLabel when the prompt fires with
		Enum.ProximityPromptInputType.Touch.

	Example:
		Called via NewInputLabel(Scope, inputType, Prompt, Config).

	Gotchas:
		- ImageTransparency starts at 1. The card's CanvasGroup GroupTransparency
		  fades everything in together, so we don't animate this label directly.

	Seam note:
		Uses Scope:New from the vendored Seam library. See module docs for basics.
]]
return function(Scope : any, Prompt : ProximityPrompt, Config : {})
    return {
        Scope:New("ImageLabel", {
            Name = "ButtonImage",
            ImageColor3 = Config.TextColor,
            BackgroundTransparency = 1,
            ImageTransparency = 1,
            Size = UDim2.fromOffset(25, 31),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png",
        })
    }
end