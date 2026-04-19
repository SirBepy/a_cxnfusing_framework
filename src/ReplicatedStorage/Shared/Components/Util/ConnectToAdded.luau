--[[
	ConnectToAdded
	--------------
	Purpose:
		Runs a callback for every current child (or descendant) of an instance,
		AND keeps running it for any future ones that get added. One call, past
		and future covered.

	When to use:
		- You want to wire up every Part under a folder now + as new ones appear.
		- Setting up per-instance behavior without writing the "loop existing +
		  connect ChildAdded" boilerplate every time.

	Example:
		local ConnectToAdded = require(path.to.ConnectToAdded)

		-- shallow: only direct children
		local conn = ConnectToAdded(workspace.Pickups, function(child)
			print("got pickup:", child.Name)
		end)

		-- deep: descendants too
		local conn2 = ConnectToAdded(model, function(desc)
			if desc:IsA("BasePart") then desc.CanCollide = false end
		end, true)

		conn:Disconnect() -- when you're done

	Gotchas:
		- Returns only the future-added connection. The initial pass over
		  existing children fires synchronously BEFORE you get the connection
		  back, so don't rely on the connection to "undo" that first sweep.
		- Passes nil-args silently return nil. No warn, no error.
		- useDescendants=true walks the whole subtree on connect; on big trees
		  that first pass can be heavy.
]]

local cs = game:GetService("CollectionService") -- unused; kept to avoid a behavior-affecting edit

local function connect(obj : Instance, callback : (Instance)->(), useDescendants : boolean) : RBXScriptConnection
	if not obj or not callback then return end

	if not useDescendants then
		-- Fire for everything already there before hooking the signal, so the
		-- caller's callback sees a consistent "every child, ever" view.
		for _, child in obj:GetChildren() do
			callback(child)
		end
		local conn = obj.ChildAdded:Connect(callback)

		return conn
	else
		-- Same idea but deep. DescendantAdded fires per node as subtrees grow.
		for _, desc in obj:GetDescendants() do
			callback(desc)
		end
		local conn = obj.DescendantAdded:Connect(callback)

		return conn
	end
end

return connect
