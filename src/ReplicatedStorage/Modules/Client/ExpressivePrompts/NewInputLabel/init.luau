--[[
	NewInputLabel
	-------------
	Purpose:
		Picks the right glyph-builder for the device the prompt is being
		shown on (gamepad, touch, or keyboard as the default fallback) and
		returns the Instances that should be parented into the round frame.

	When to use:
		Internal dispatch used by ExpressivePrompts/init.luau once per prompt.

	Example:
		local children = NewInputLabel(PromptScope, Enum.ProximityPromptInputType.Gamepad, Prompt, Config)

	Gotchas:
		- Any input type not in the lookup falls back to Keyboard so we never
		  render a blank card.

	Seam note:
		The returned table is passed straight to Seam.Children - see the
		module docs for Seam basics.
]]

-- Constants
local INPUT_KEY_LABELS = {
    [Enum.ProximityPromptInputType.Gamepad] = require(script.Gamepad),
    [Enum.ProximityPromptInputType.Touch] = require(script.Touch),
    ["Default"] = require(script.Keyboard),
}

return function(Scope : any, inputType, prompt, Config : {})
    local Component = INPUT_KEY_LABELS[inputType] or INPUT_KEY_LABELS["Default"]

    return Component(Scope, prompt, Config)
end