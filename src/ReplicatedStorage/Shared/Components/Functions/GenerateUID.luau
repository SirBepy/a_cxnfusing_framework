--[[
	GenerateUID.

	Purpose:
		Spit out a random unique-ish string ID. Thin wrapper around
		HttpService:GenerateGUID with the dashes stripped out.

	When to use:
		Whenever you need a throwaway identifier: tagging pooled instances,
		keying a local dictionary, correlating a request/response, naming
		an anonymous VFX emitter. Not cryptographically secure, just unique.

	Example:
		local id = GenerateUID()
		-- id -> "5F2B...A81C" (32 hex chars, no dashes)

	Gotchas:
		- No args, no config. If you want dashes, call HttpService directly.
		- HttpService:GenerateGUID works fine on client and server without
		  the HttpEnabled flag, despite the service name.
]]

local HttpService = game:GetService("HttpService")
return function()
	local GUID = HttpService:GenerateGUID(false)
	-- Dashes get in the way when IDs are used as instance names or attribute
	-- keys, so we strip them by default.
	local final = string.gsub(GUID, "-", "")
	return final
end
