--[[
	Networker (entry point)

	Purpose:
		Small server<->client RPC helper DataService uses for replication. Each
		Networker is identified by a tag (string or an Instance) and owns a
		RemoteEvent + RemoteFunction pair. Server decides what the client is
		allowed to call; client calls `fire`/`fetch` with a method name.

	When to use:
		DataService is the main consumer. You can reuse it for other
		service-style replication if you want the same access-whitelist pattern,
		but most gameplay networking should go through `Shared/Network` instead.

	Example:
		-- server
		local net = Networker.server.new("Scores", ScoresService, { ScoresService.get })
		net:fire(player, "onScoreUpdate", newScore)

		-- client
		local net = Networker.client.new("Scores", Scores)
		local score = net:fetch("get", userId)

	Gotchas:
		- Same server-only / client-only split as DataService: `.server` is a
		  stub on the client and vice versa. Pick the matching half.
		- Tags must be unique on the server; re-using a string tag will assert.
		- If you pass an Instance as the tag, the networker attaches a GUID
		  attribute to it and destroys itself when the Instance is destroyed.
]]

local server = require(script.NetworkerServer)
local client = require(script.NetworkerClient)

export type Server = server.NetworkerServer
export type Client = client.NetworkerClient

return {
	server = server,
	client = client,
}
