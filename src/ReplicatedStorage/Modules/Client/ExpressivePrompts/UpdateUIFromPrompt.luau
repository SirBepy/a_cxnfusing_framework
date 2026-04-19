--[[
	UpdateUIFromPrompt
	------------------
	Purpose:
		Syncs the UI to the current ProximityPrompt state: measures ActionText
		and ObjectText, lays them out, sizes the BillboardGui to fit, and
		updates the card's aspect ratio so it morphs nicely to new text.

	When to use:
		Called once at prompt creation and again on every Prompt.Changed so
		devs can live-edit ActionText/ObjectText/UIOffset and see it update.

	Example:
		UpdateUIFromPrompt(PromptScope, Prompt, PromptUI, AspectRatioValue, ActionText, ObjectText)

	Gotchas:
		- Text measurement uses a fixed 1000x1000 bound - pathologically long
		  strings won't wrap correctly. Fine for typical prompts.
		- Writes directly to PromptUI.Size (non-reactive) so it must be called
		  whenever text changes.

	Seam note:
		Scope:New here just re-applies props to existing Instances - Seam's
		way of saying "patch these bindings". See the module docs for Seam basics.
]]

-- Services
local TextService = game:GetService("TextService")

return function(Scope : any, Prompt : ProximityPrompt, PromptUI : BillboardGui, AspectRatioValue : any, ActionText : TextLabel, ObjectText : TextLabel)
    local actionTextSize = TextService:GetTextSize(
        Prompt.ActionText,
        19,
        Enum.Font.GothamMedium,
        Vector2.new(1000, 1000)
    )

    local objectTextSize = TextService:GetTextSize(
        Prompt.ObjectText,
        14,
        Enum.Font.GothamMedium,
        Vector2.new(1000, 1000)
    )

    -- Default to 72x72 (icon-only). If there's any text, grow the card wide
    -- enough to fit the longest line plus left padding for the glyph and a
    -- bit of right breathing room.
    local maxTextWidth = math.max(actionTextSize.X, objectTextSize.X)
    local promptHeight = 72
    local promptWidth = 72
    local textPaddingLeft = 72

    if
        (Prompt.ActionText ~= nil and Prompt.ActionText ~= "")
        or (Prompt.ObjectText ~= nil and Prompt.ObjectText ~= "")
    then
        promptWidth = maxTextWidth + textPaddingLeft + 24
    end

    -- Nudge ActionText down by 9px when ObjectText is present so the two
    -- stack cleanly instead of ActionText sitting dead-center.
    local actionTextYOffset = 0
    if Prompt.ObjectText ~= nil and Prompt.ObjectText ~= "" then
        actionTextYOffset = 9
    end

    Scope:New(ActionText, {
        Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, actionTextYOffset),
        Text = Prompt.ActionText,
        AutoLocalize = Prompt.AutoLocalize,
        RootLocalizationTable = Prompt.RootLocalizationTable,
    })

    Scope:New(ObjectText, {
        Position = UDim2.new(0.5, textPaddingLeft - promptWidth / 2, 0, -10),
        Text = Prompt.ObjectText,
        AutoLocalize = Prompt.AutoLocalize,
        RootLocalizationTable = Prompt.RootLocalizationTable,
    })

    PromptUI.Size = UDim2.fromOffset(promptWidth, promptHeight)
    -- SizeOffset is expressed in multiples of the BillboardGui's own size, so
    -- convert the dev's pixel UIOffset into that ratio.
    PromptUI.SizeOffset = Vector2.new(
        Prompt.UIOffset.X / PromptUI.Size.Width.Offset,
        Prompt.UIOffset.Y / PromptUI.Size.Height.Offset
    )

    -- Feed the new aspect ratio into the Seam Value so the UIAspectRatioConstraint
    -- spring animates the card morph instead of snapping.
    AspectRatioValue.Value = promptWidth / promptHeight
end