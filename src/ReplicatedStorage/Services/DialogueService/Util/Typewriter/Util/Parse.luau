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
		activeEffects[tagName] = not isClosing or nil

		lastPos = tagEnd + 1
	end

	return instructions, table.concat(cleanTextTable)
end