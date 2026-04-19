--[[
	DataService (entry point)

	Purpose:
		Single require that hands you both halves of the data layer. The server
		half wraps ProfileStore (vendored) and owns the real data. The client
		half mirrors it and listens for replicated changes.

	When to use:
		Any time you need persistent per-player data (currency, inventory,
		settings, tutorial progress, etc). Use `.server` from server scripts
		and `.client` from LocalScripts.

	Example:
		-- server
		local DataService = require(path.to.DataService).server
		DataService:init({ template = myTemplate, profileStoreIndex = "Live" })

		-- client
		local DataService = require(path.to.DataService).client
		DataService:init()
		print(DataService:get({ "currency" }))

	Gotchas:
		- `.server` is a live module on the server but an empty stub on the client.
		  `.client` is the opposite. Grabbing the wrong half from the wrong context
		  gives you a table with no methods (silent misuse). Always pick the half
		  that matches your script context.
		- ProfileStore lives under this folder and is VENDORED. Don't edit it.
		- `:init(...)` must be called before any other method on either half.
]]

local server = require(script.DataServiceServer)
local client = require(script.DataServiceClient)

export type Server = server.DataServiceServer
export type Client = client.DataServiceClient

return {
	server = server,
	client = client,
}
