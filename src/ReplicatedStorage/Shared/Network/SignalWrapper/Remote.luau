--[[
	Remote
	======

	Purpose:
		Factory for a single "global event" object. One call gives you an
		object that wraps BOTH a RemoteEvent (for fire-and-forget) and a
		RemoteFunction (for request/response), sharing a name. The same
		returned object works on server and client; it just exposes different
		methods depending on which context required it.

	When to use:
		You don't call this directly in user code. `Network.newGlobal(name)`
		calls this with the shared Remotes folder. Read this if you want to
		know exactly what API a global event exposes.

	Example:
		-- server
		local ev = remote("Damage", remotesFolder)
		ev:FireClient(player, 10)
		ev:Connect(function(plr, amount) ... end)  -- OnServerEvent
		ev.OnInvoke = function(plr, ...) return ... end

		-- client
		local ev = remote("Damage", remotesFolder)
		ev:FireServer(10)
		ev:Connect(function(amount) ... end)       -- OnClientEvent

	Gotchas:
		- If a RemoteEvent / RemoteFunction with the expected names already
		  exists under `rems`, this reuses them. That means both server and
		  client can call this factory for the same name and they'll share
		  instances without racing each other.
		- `FireClient` / `InvokeClient` silently `return` when given a bad
		  Player argument. Bad input = nothing happens, no error. Watch for
		  that when debugging "why didn't my event fire".
		- Client-context objects do not have FireClient/FireAllClients; server
		  objects do not have FireServer/InvokeServer. The split is static per
		  context.
		- `OnInvoke` is a plain function (dot call), not a method (colon). The
		  rest of the API uses colon style. Inconsistent but intentional so
		  far.
]]

local function isClient()
	return game:GetService("RunService"):IsClient()
end

return function(name : string, rems : Instance)

	assert(rems, "Parent folder (rems) is required")

	-- Reuse an existing RemoteEvent with this name if one is already there
	-- (e.g. the other side of the connection created it first). Otherwise
	-- make a new one. Either way we end up with a shared instance.
	local remote : RemoteEvent = rems:FindFirstChild(name) :: RemoteEvent
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = rems
	end

	-- Paired RemoteFunction for the invoke (request/response) half. Named
	-- `<name>_Invoke` so it sits next to the RemoteEvent without colliding.
	local invokeRemote : RemoteFunction = rems:FindFirstChild(name .. "_Invoke") :: RemoteFunction
	if not invokeRemote then
		invokeRemote = Instance.new("RemoteFunction")
		invokeRemote.Name = name .. "_Invoke"
		invokeRemote.Parent = rems
	end

	-- Tracks every connection we hand out so :DisconnectAll / :Destroy can
	-- tear them down in one sweep.
	local connections = {}
	local conn = {}
	conn.__index = conn

	function conn.new(func : (...any)->())
		local remConn

		-- Context decides which event to bind to. Client listens on
		-- OnClientEvent (server fired at me); server listens on
		-- OnServerEvent (some client fired at me).
		if isClient() then
			remConn = remote.OnClientEvent:Connect(func)
		else
			remConn = remote.OnServerEvent:Connect(func)
		end

		local self = setmetatable({
			RemConn = remConn
		}, conn)

		table.insert(connections, self)
		return self
	end

	function conn.once(func : (...any)->())
		local self = setmetatable({}, conn)

		-- Wrap so the connection auto-disconnects BEFORE the user's callback
		-- runs. Doing it first means a callback that errors still cleans up.
		local function wrapper(...)
			self:Disconnect()
			func(...)
		end

		if isClient() then
			self.RemConn = remote.OnClientEvent:Connect(wrapper)
		else
			self.RemConn = remote.OnServerEvent:Connect(wrapper)
		end

		table.insert(connections, self)
		return self
	end

	function conn.wait() : (...any)
		-- Yield the current thread until the next fire. Returns whatever
		-- args were fired, just like a regular RBXScriptSignal:Wait.
		if isClient() then
			return remote.OnClientEvent:Wait()
		else
			return remote.OnServerEvent:Wait()
		end
	end

	function conn:Disconnect()
		-- Remove from our bookkeeping table so DisconnectAll doesn't try to
		-- double-disconnect a dead entry later.
		local index = table.find(connections, self)
		if index then
			table.remove(connections, index)
		end

		if self.RemConn then
			self.RemConn:Disconnect()
			self.RemConn = nil
		end

		-- Unlinking the metatable makes further method calls error loudly
		-- instead of silently hitting the dead entry's cached methods.
		setmetatable(self, nil)
	end

	local new = {}

	-- The API surface splits here by context. We define the Fire/Invoke
	-- methods that make sense for the side we're on and leave the others
	-- undefined so mistaken calls error out fast rather than being silent.
	if isClient() then
		function new:FireServer(... : any)
			remote:FireServer(...)
		end

		function new:InvokeServer(... : any)
			return invokeRemote:InvokeServer(...)
		end
	else
		function new:FireClient(plr : Player, ... : any)
			-- Silently bail on bad player arg. Noted gotcha: if nothing
			-- seems to fire, double-check you passed a real Player.
			if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
				return
			end
			remote:FireClient(plr, ...)
		end

		function new:FireAllClients(... : any)
			remote:FireAllClients(...)
		end

		function new:InvokeClient(plr : Player, ... : any)
			-- InvokeClient can yield and can throw if the client errors.
			-- Only do this when you actually need a response from a client.
			if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
				return
			end
			return invokeRemote:InvokeClient(plr, ...)
		end
	end

	function new:Connect(callback : (...any)->())
		return conn.new(callback)
	end

	function new:Once(callback : (...any)->())
		return conn.once(callback)
	end

	function new:Wait()
		return conn.wait()
	end

	-- Dot-call, not colon. Sets the invoke handler for this context.
	-- Only one handler can exist at a time on a RemoteFunction, so calling
	-- this twice overwrites the previous callback.
	function new.OnInvoke(callback : (player : Player, ...any)->(...any))
		if isClient() then
			invokeRemote.OnClientInvoke = callback
		else
			invokeRemote.OnServerInvoke = callback
		end
	end

	function new:DisconnectAll()
		for _, c in ipairs(connections) do
			c:Disconnect()
		end
		table.clear(connections)
	end

	function new:Destroy()
		new:DisconnectAll()

		-- Destroying the underlying Instances affects BOTH sides of the
		-- wire, since there's only one RemoteEvent/RemoteFunction per name.
		-- Don't call Destroy unless you actually want to tear the channel
		-- down for everyone.
		invokeRemote:Destroy()
		remote:Destroy()

		table.clear(new)
	end

	return new
end