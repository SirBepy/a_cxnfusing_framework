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
		-- We check if we are at the start of a word to see if the WHOLE word fits
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