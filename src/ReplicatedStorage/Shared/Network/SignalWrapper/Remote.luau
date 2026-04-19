local function isClient()
	return game:GetService("RunService"):IsClient()
end

return function(name : string, rems : Instance)

	assert(rems, "Parent folder (rems) is required")

	local remote : RemoteEvent = rems:FindFirstChild(name) :: RemoteEvent
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = rems
	end

	local invokeRemote : RemoteFunction = rems:FindFirstChild(name .. "_Invoke") :: RemoteFunction
	if not invokeRemote then
		invokeRemote = Instance.new("RemoteFunction")
		invokeRemote.Name = name .. "_Invoke"
		invokeRemote.Parent = rems
	end

	local connections = {}
	local conn = {}
	conn.__index = conn

	function conn.new(func : (...any)->())
		local remConn

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
		if isClient() then
			return remote.OnClientEvent:Wait()
		else
			return remote.OnServerEvent:Wait()
		end
	end

	function conn:Disconnect()
		local index = table.find(connections, self)
		if index then
			table.remove(connections, index)
		end

		if self.RemConn then
			self.RemConn:Disconnect()
			self.RemConn = nil
		end

		setmetatable(self, nil)
	end

	local new = {}

	if isClient() then
		function new:FireServer(... : any)
			remote:FireServer(...)
		end

		function new:InvokeServer(... : any)
			return invokeRemote:InvokeServer(...)
		end
	else
		function new:FireClient(plr : Player, ... : any)
			if typeof(plr) ~= "Instance" or not plr:IsA("Player") then
				return
			end
			remote:FireClient(plr, ...)
		end

		function new:FireAllClients(... : any)
			remote:FireAllClients(...)
		end

		function new:InvokeClient(plr : Player, ... : any)
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

		invokeRemote:Destroy()
		remote:Destroy()

		table.clear(new)
	end

	return new
end