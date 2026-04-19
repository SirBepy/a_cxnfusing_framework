--[[
	Replace

	Purpose:
		Pre-processes a dialogue Text string before it's handed to the
		typewriter. Two jobs:
		  1. Swap simple `<plrName>` / `<npcName>` placeholders for real
		     values.
		  2. Strip out `$cmd:arg$` commands and return them as a
		     separate table keyed by the VISIBLE character index they
		     sat on, so DialogueHandler can fire them at the right moment.

	When to use:
		Called internally by DialogueHandler right before each node's
		text is typed. You usually won't call it yourself.

	Example:
		local text, commands = replace("Hi $pose:Wave$<plrName>!", npc, plr)
		-- text     -> "Hi Joe!"
		-- commands -> { [2] = { command = "pose", arguments = "Wave" } }
		-- (Index 2 = the space before "Joe", i.e. the next letter to type)

	Gotchas:
		- `<...>` tags that aren't the two known placeholders are left
		  alone on purpose so the typewriter's own parser can read effect
		  tags like <b>, <wave>, etc.
		- A lone `$` with no matching closing `$` is treated as a literal
		  dollar sign.
		- The command index is 0-based for commands sitting BEFORE the
		  first visible letter (see DialogueHandler for the index-0 fire).
--]]

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
			-- Non-greedy `.-` so "$a$ $b$" captures "a" then "b",
			-- not "a$ $b".
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
			-- Preserve the WHOLE tag verbatim (including the angle
			-- brackets). The typewriter's parser reads these later for
			-- effects like <b>, <wave>, etc. visibleIndex does NOT
			-- advance because the tag produces zero visible characters.
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