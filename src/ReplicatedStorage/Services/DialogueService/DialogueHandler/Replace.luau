local function rep(message: string, npc: Model, player: Player) : (string, {[number] : {command: string, arguments: any}})
	local replaceList = {
		["<plrName>"] = player.DisplayName,
		["<npcName>"] = npc.Name,
	}

	local commands = {}

	for original, new in pairs(replaceList) do
		message = message:gsub(original, new)
	end

	local output = ""
	local visibleIndex = 0
	local i = 1

	while i <= #message do
		local c = message:sub(i,i)

		if c == "$" then
			local s, e, content = message:find("%$(.-)%$", i)

			if s then
				local cmd, arg
				local colonPos = content:find(":")

				if colonPos then
					cmd = content:sub(1, colonPos - 1)
					arg = content:sub(colonPos + 1)
				else
					cmd = content
					arg = nil
				end

				if cmd ~= "" then
					commands[visibleIndex] = {
						command = cmd,
						arguments = (arg ~= "" and arg or nil)
					}
				end

				i = e + 1
			else
				output = output .. "$"
				visibleIndex = visibleIndex + 1
				i = i + 1
			end
		elseif c == "<" then
			local s, e = message:find(">", i)
			if s then
				output = output .. message:sub(i, e)
				i = e + 1
			else
				output = output .. c
				visibleIndex = visibleIndex + 1
				i = i + 1
			end
		else
			output = output .. c
			visibleIndex = visibleIndex + 1
			i = i + 1
		end
	end

	return output, commands
end

return rep