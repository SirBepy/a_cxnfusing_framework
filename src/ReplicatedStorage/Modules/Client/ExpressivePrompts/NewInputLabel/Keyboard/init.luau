--[[
    Keyboard input label
    --------------------
    Purpose:
        Builds the keyboard cap art for a prompt: the shared key-cap base
        image plus either a centered glyph (Return, Shift, spacebar, etc.)
        or a TextLabel with the printable character.

    When to use:
        Internal - selected by NewInputLabel for keyboard (and as the
        default fallback for unknown input types).

    Example:
        Called via NewInputLabel(Scope, inputType, Prompt, Config).

    Gotchas:
        - Errors loudly if the KeyCode has no glyph AND no printable text
          AND no text override. Beginners: this means you set an exotic
          KeyboardKeyCode that the three lookup tables don't cover. Add an
          entry or change the key.
        - Uses a smaller TextSize (12) when the label is 3+ chars (e.g.
          "Ctrl", "F12") so it still fits inside the cap.

    Seam note:
        Uses Scope:New from the vendored Seam library. See module docs.
]]

-- Constants
local KEYBOARD_BUTTON_IMAGE = require(script.KeyboardButtonImage)
local KEYBOARD_BUTTON_ICON_MAPPING = require(script.KeyboardButtonIconMapping)
local KEYCODE_TO_TEXT_MAPPING = require(script.KeyCodeToTextMapping)

-- Services
local UserInputService = game:GetService("UserInputService")

return function(Scope : any, prompt, Config : {})
    local AddedChildren = {}
    -- GetStringForKeyCode respects the user's keyboard layout (AZERTY vs QWERTY etc).
	local buttonTextString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)

	-- Three-tier glyph resolution:
	--   1) KEYBOARD_BUTTON_IMAGE - keyed by KeyCode (Return, Shift, Backspace...)
	--   2) KEYBOARD_BUTTON_ICON_MAPPING - keyed by printable char (spacebar, comma...)
	--   3) KEYCODE_TO_TEXT_MAPPING - override raw char with a friendly label ("Ctrl", "F1"...)
	-- Whichever hits first wins; TextLabel fallback handles plain printable keys.
	local buttonTextImage = KEYBOARD_BUTTON_IMAGE[prompt.KeyboardKeyCode]
	if buttonTextImage == nil then
		buttonTextImage = KEYBOARD_BUTTON_ICON_MAPPING[buttonTextString]
	end

	if buttonTextImage == nil then
		local keyCodeMappedText = KEYCODE_TO_TEXT_MAPPING[prompt.KeyboardKeyCode]
		if keyCodeMappedText then
			buttonTextString = keyCodeMappedText
		end
	end

	AddedChildren[#AddedChildren + 1] = Scope:New("ImageLabel", {
		Name = "ButtonImage",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(28, 30),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Image = "rbxasset://textures/ui/Controls/key_single.png",
		ImageColor3 = Config.TextColor,
	})

	if buttonTextImage then
		AddedChildren[#AddedChildren + 1] = Scope:New("ImageLabel", {
			Name = "ButtonImage",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(36, 36),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = buttonTextImage,
			ImageColor3 = Config.TextColor,
		})
	elseif buttonTextString ~= nil and buttonTextString ~= "" then
		AddedChildren[#AddedChildren + 1] = Scope:New("TextLabel", {
			Name = "ButtonText",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromOffset(0, -1),
			Font = Enum.Font.GothamMedium,
			-- Shrink font for multi-char labels ("Ctrl", "Alt", "F12") so they fit inside the cap.
		TextSize = if string.len(buttonTextString) > 2 then 12 else 14,
			BackgroundTransparency = 1,
			TextColor3 = Config.TextColor,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = buttonTextString,
		})
	else
		error(
			"ProximityPrompt '"
				.. prompt.Name
				.. "' has an unsupported keycode for rendering UI: "
				.. tostring(prompt.KeyboardKeyCode)
		)
	end
    
    return AddedChildren
end