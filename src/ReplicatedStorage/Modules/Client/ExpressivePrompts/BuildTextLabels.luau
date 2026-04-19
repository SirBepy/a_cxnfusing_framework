--[[
	BuildTextLabels
	---------------
	Purpose:
		Creates the two TextLabels that show the prompt's ActionText (main line)
		and ObjectText (sub line). Positioning/sizing is done later by
		UpdateUIFromPrompt once it knows how wide the text will be.

	When to use:
		Internal to ExpressivePrompts. Called once per prompt in init.luau.

	Example:
		local ActionText, ObjectText = unpack(BuildTextLabels(PromptScope, Config, Frame, ButtonHeldDown))

	Gotchas:
		- Both labels fade out while ButtonHeldDown so the card reads as "pressing"
		  without distracting text. If you remove the spring the hold state
		  feels weirdly verbose.

	Seam note:
		Uses the vendored Seam library (Scope:New, Spring, Computed). If you're
		new to those, see the module's docs page for a tutorial.
]]
return function(Scope : any, Config : {}, ParentFrame : Instance, ButtonHeldDown : any) : {any}
    local ActionText = Scope:New("TextLabel", {
		Name = "ActionText",
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamMedium,
		TextSize = 19,
		BackgroundTransparency = 1,
		TextColor3 = Config.TextColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ParentFrame,

		-- Fade text out while held to declutter the "pressed" look. Spring
		-- uses critical damping (1.0) so no wobble on the fade.
		TextTransparency = Scope:Spring(Scope:Computed(function(Use)
			return Use(ButtonHeldDown) and 1 or 0
		end), 30, 1)
	})

	local ObjectText = Scope:New("TextLabel", {
		Name = "ObjectText",
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		BackgroundTransparency = 1,
		TextColor3 = Config.SubTextColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ParentFrame,

		-- Fade text out while held to declutter the "pressed" look. Spring
		-- uses critical damping (1.0) so no wobble on the fade.
		TextTransparency = Scope:Spring(Scope:Computed(function(Use)
			return Use(ButtonHeldDown) and 1 or 0
		end), 30, 1)
	})

    return {ActionText, ObjectText}
end