--[[
	Layout

	Purpose:
		Cursor/word-wrap helper for Typewriter's "Letter" mode. Given a
		character + its surrounding clean text, returns the UDim2 offset
		where the next letter's TextLabel should sit. Also handles
		newlines and swaps to a Bold font variant when the <b> effect
		is active on that character.

	When to use:
		Typewriter creates one Layout per :Type call and asks it for
		positions letter-by-letter. You'd only use it directly if you
		were building a different text renderer with similar needs.

	Example:
		local layout = Layout.new(label.Font, frame.AbsoluteSize.X, 18)
		local pos = layout:GetNextPosition("H", "Hello", 1, {})
		newLabel.Position = pos -- UDim2.fromOffset(...)

	Gotchas:
		- BOLD_MAP only covers a handful of fonts; any other base font
		  won't get a real bold variant (falls back to the regular font).
		- Word-wrap peeks ahead with `cleanText:find("%s", ...)` from the
		  CURRENT index, so it assumes `cleanText` is the FULL stripped
		  string, not just what's typed so far.
		- Returns `nil` for newlines (caller should treat nil as "skip
		  spawning a label for this char").
--]]

local TextService = game:GetService("TextService")

local Layout = {}

-- CONFIG
local PADDING = 0 -- Extra pixels between letters if needed
local LINE_HEIGHT_MULT = 1.2

local BOLD_MAP = {
	[Enum.Font.SourceSans] = Enum.Font.SourceSansBold,
	[Enum.Font.Gotham] = Enum.Font.GothamBold,
	[Enum.Font.Arial] = Enum.Font.ArialBold,
	[Enum.Font.BuilderSans] = Enum.Font.BuilderSansBold,
	[Enum.Font.Montserrat] = Enum.Font.MontserratBold,
	[Enum.Font.Arimo] = Enum.Font.ArimoBold,
}

local function getFontVariant(baseFont: Enum.Font, effects: {string})
	if table.find(effects, "b") then
		return BOLD_MAP[baseFont] or baseFont
	end
	return baseFont
end

function Layout.new(baseFont: Font, frameWidth: number, fontSize: number)
	
	local self = {
		
		frameWidth = frameWidth,
		font = baseFont,
		fontSize = fontSize,

		cursorX = 0,
		cursorY = 0,
		lineHeight = fontSize * LINE_HEIGHT_MULT
		
	}

	function self:GetNextPosition(char: string, cleanText: string, currentIndex: number, effects: {string})
		-- 1. Handle Newlines
		if char == "\n" or char == "\13" then
			self.cursorX = 0
			self.cursorY += self.lineHeight
			return nil
		end

		-- 2. Determine Font for this specific character
		local currentFont = getFontVariant(self.font, effects)

		-- 3. Word Wrap Logic
		-- Only measure once per word, at its first letter. If the whole
		-- word would overflow the frame, bump the cursor to a new line
		-- BEFORE placing the first letter, so the word stays intact.
		local isStartOfWord = (currentIndex == 1 or cleanText:sub(currentIndex-1, currentIndex-1):match("%s"))

		if isStartOfWord and not char:match("%s") then
			local nextSpace = cleanText:find("%s", currentIndex) or (#cleanText + 1)
			local word = cleanText:sub(currentIndex, nextSpace - 1)

			-- Measure the word using the bold font if applicable
			local wordSize = TextService:GetTextSize(word, self.fontSize, currentFont, Vector2.new(10000, 10000))

			if self.cursorX + wordSize.X > self.frameWidth then
				self.cursorX = 0
				self.cursorY += self.lineHeight
			end
		end

		-- 4. Calculate Character Position
		local charSize = TextService:GetTextSize(char, self.fontSize, currentFont, Vector2.new(10000, 10000))
		local pos = UDim2.fromOffset(self.cursorX, self.cursorY)

		-- 5. Advance Cursor
		self.cursorX += (charSize.X + PADDING)

		return pos
	end

	function self:Destroy()
		for i, v in self do self[i] = nil end
	end

	return self
end

return Layout