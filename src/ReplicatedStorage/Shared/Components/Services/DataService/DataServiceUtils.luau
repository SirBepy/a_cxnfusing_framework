--[[
	DataServiceUtils

	Purpose:
		Shared enums for the DataService server<->client protocol. Numeric
		action ids are what travel over the wire instead of method name strings
		- smaller + less error-prone.

	When to use:
		Only referenced internally by DataServiceServer/Client. You shouldn't
		need to touch this unless adding a new replicated mutation op.

	Example:
		-- server firing a replicated "set" to the client
		networker:fire(player, DataServiceUtils.enums.actions.set, path, value)

	Gotchas:
		- IDs are load-bearing: they key into DataServiceClient method aliases.
		  Changing an id breaks live clients vs servers on mismatched versions.
		  Append new ops, don't renumber.
		- Neutral file, safe on both server and client.
]]

local DataServiceUtils = {}

DataServiceUtils.enums = {
	actions = {
		init = 0,
		set = 1,
		arrayInsert = 2,
		arrayRemove = 3,
	},
}

return DataServiceUtils
