--[[
    Gamepad input label
    -------------------
    Purpose:
        Looks up the right Xbox-style glyph for the prompt's GamepadKeyCode
        and returns an ImageLabel showing it.

    When to use:
        Internal - selected by NewInputLabel on controller input.

    Example:
        Called via NewInputLabel(Scope, inputType, Prompt, Config).

    Gotchas:
        - Returns nil (not an empty table) when the KeyCode isn't mapped.
          Callers feed the result straight to Seam.Children, which treats nil
          as "no kids". Intentional silent fallback.

    Seam note:
        Uses Scope:New from the vendored Seam library. See module docs.
]]

-- Constants
local GAMEPAD_BUTTON_IMAGE = require(script.GamepadButtonImage)

return function(Scope : any, prompt, Config : {})
    -- Bail silently on unmapped keycodes so the prompt still appears (just
    -- without a glyph). Caller handles nil gracefully via Seam.Children.
    if not GAMEPAD_BUTTON_IMAGE[prompt.GamepadKeyCode] then
        return
    end

    return {
        Scope:New("ImageLabel", {
            Name = "ButtonImage",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageTransparency = 1,
            Image = GAMEPAD_BUTTON_IMAGE[prompt.GamepadKeyCode],
            ImageColor3 = Config.TextColor,
        })
    }
end