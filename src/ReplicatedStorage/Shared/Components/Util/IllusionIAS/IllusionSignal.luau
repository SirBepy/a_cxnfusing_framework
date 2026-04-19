--!strict
--IllusionSignal.luau
--[[
	IllusionSignal (internal to IllusionIAS)
	----------------------------------------
	Purpose:
		Minimal linked-list signal/event implementation used by IllusionIAS's
		Activated / Started / Ended events. Connect, Once, Wait, Fire,
		DisconnectAll. Nothing fancy, no pooling, no queueing.

	When to use:
		Internal. Use the Activated/Started/Ended fields on an IIAS action.
		If you need a general-purpose signal elsewhere, grab Lemoine's
		SignalPlus or similar from Packages.

	Example (internal):
		local sig = IllusionSignal.new()
		sig:Connect(function(v) print(v) end)
		sig:Fire(true, true)

	Gotchas:
		- Fire runs handlers synchronously on the calling thread. An error
		  in one handler will interrupt the rest.
		- Wait yields the current coroutine until the next Fire.
]]

local IAS = require("./TypeDefinition")

return {
	new = function(): IAS.IAScriptSignal
		-- Signal state is a singly-linked list of nodes. New connections
		-- prepend at `head`, disconnects splice the list. No array shuffling.
		local head: IAS.Node? = nil

		local function createConnection(node: IAS.Node): IAS.IAScriptConnection
			local connected = true

			local conn: IAS.IAScriptConnection = {
				Connected = true,
				Disconnect = function(self)
					if not connected then return end
					connected = false
					self.Connected = false

					if head == node then
						head = node.next
						return
					end

					local current = head
					while current and current.next ~= node do
						current = current.next
					end

					if current then
						current.next = node.next
					end
				end,
			}

			return conn
		end

		local Signal: IAS.IAScriptSignal = {
			Connect = function(self: IAS.IAScriptSignal, fn: IAS.func): IAS.IAScriptConnection
				local node: IAS.Node = {
					fn = fn,
					next = head,
				}

				head = node
				return createConnection(node)
			end,

			Once = function(self: IAS.IAScriptSignal, fn: IAS.func): IAS.IAScriptConnection
				local fired = false
				local conn: IAS.IAScriptConnection

				conn = self:Connect(function(...)
					if fired then return end
					fired = true
					conn:Disconnect()
					fn(...)
				end)

				return conn
			end,

			Wait = function(self: IAS.IAScriptSignal): IAS.variant
				local thread = coroutine.running()
				local conn: IAS.IAScriptConnection
				local args: {any}? = nil

				conn = self:Connect(function(...)
					conn:Disconnect()
					args = table.pack(...)
					task.spawn(thread)
				end)

				coroutine.yield()
				return table.unpack(args or {})
			end,

			Fire = function(self: IAS.IAScriptSignal, active: IAS.variant, pressed: boolean?)
				-- Walk the list. We advance `node` *before* calling `fn` so a
				-- handler disconnecting itself mid-fire doesn't break iteration.
				local node = head
				while node do
					local fn = node.fn
					node = node.next
					if fn then
						fn(active, pressed)
					end
				end
			end,

			DisconnectAll = function(self)
				local node = head
				while node do
					node.fn = nil::any
					local nextNode = node.next
					node.next = nil
					node = nextNode
				end
				head = nil
			end

		}

		return Signal
	end
}
