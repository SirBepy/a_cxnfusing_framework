--[[
	Parse

	Purpose:
		Splits a raw dialogue string (including `<effect>...</effect>`
		tags) into:
		  1. A per-character instruction table - for each visible
		     character, records the Letter, its visible Index, and which
		     effects are active at that moment.
		  2. A "clean" string with all tags stripped, used by Layout for
		     word-wrap measurement.

	When to use:
		Typewriter calls this once before typing starts. You'd only
		reach for it directly if you were building a custom renderer.

	Example:
		local data, clean = parse("Hi <wave>there</wave>!")
		-- clean    -> "Hi there!"
		-- data[4]  -> { Letter="t", Index=4, Effects={"wave"} }

	Gotchas:
		- Tag pattern is `<(/?)(%w+)>` so tags must be word-chars only
		  and can't nest identically-named tags (closing clears the flag
		  regardless of how many opens came before).
		- By assigning `true or nil`, closed effects are REMOVED from
		  the active set (not set to false), which is what `getActiveList`
		  relies on.
		- Does NOT handle the `<plrName>` / `<npcName>` substitutions;
		  Replace.luau runs first and resolves those before parse sees
		  the string.
--]]

local function getActiveList(set)
	local list = {}
	for effect, active in set do
		if active then
			table.insert(list, effect)
		end
	end
	return list
end

return function(rawText: string) : ({{Letter : string, Index : number, Effects : {string}}}, string)

	local instructions = {}
	local activeEffects = {}
	local cleanTextTable = {}

	local tagPattern = "<(/?)(%w+)>"
	local lastPos = 1

	while true do
		local tagStart, tagEnd, closeSlash, tagName = rawText:find(tagPattern, lastPos)

		local textChunk = rawText:sub(lastPos, (tagStart or #rawText + 1) - 1)

		for i = 1, #textChunk do
			local char = textChunk:sub(i, i)

			table.insert(cleanTextTable, char)
			table.insert(instructions, {
				Letter = char,
				Index = #cleanTextTable, 
				Effects = getActiveList(activeEffects)
			})
		end

		if not tagStart then break end

		local isClosing = (closeSlash == "/")
		-- Opening tag -> activeEffects[name] = true.
		-- Closing tag -> activeEffects[name] = nil (removed entirely,
		-- so pairs() iteration in getActiveList skips it).
		activeEffects[tagName] = not isClosing or nil

		lastPos = tagEnd + 1
	end

	return instructions, table.concat(cleanTextTable)
end