--[[
	Network
	=======

	Purpose:
		Two tiny constructors for events. `newGlobal` gives you a networked
		event (server <-> client, backed by a RemoteEvent + RemoteFunction),
		and `newLocal` gives you an in-process signal (same script context,
		no networking at all).

	When to use:
		- newGlobal -> anytime the server needs to talk to the client, or the
		  client needs to ask/tell the server something. Pick this for any
		  cross-boundary communication.
		- newLocal  -> decoupling code inside the same context (e.g. a system
		  firing an event that other local systems listen for). Cheap, fast,
		  no replication.

		In this framework, you usually don't call these directly. You declare
		events by name in `Shared/init.luau` under `GlobalEvents` /
		`LocalEvents`, and then reach them via `Framework.GlobalEvents.MyEvent`
		or `Framework.LocalEvents.MyEvent`.

	Example (Global, server Fire + client Connect):
		-- Shared/init.luau
		GlobalEvents = {
			CoinsChanged = Network.newGlobal("CoinsChanged"),
		}

		-- server
		Framework.GlobalEvents.CoinsChanged:FireClient(plr, 50)

		-- client
		Framework.GlobalEvents.CoinsChanged:Connect(function(newAmount)
			print("I now have", newAmount, "coins")
		end)

	Example (Local, same-context Fire + Connect):
		-- Shared/init.luau
		LocalEvents = {
			PlayerHurt = Network.newLocal(),
		}

		-- anywhere in the same context
		Framework.LocalEvents.PlayerHurt:Connect(function(dmg)
			print("ouch:", dmg)
		end)
		Framework.LocalEvents.PlayerHurt:Fire(25)

	Gotchas:
		- newGlobal expects a `Remotes` folder under this Network module.
		  SignalWrapper looks it up with WaitForChild; if it's missing, the
		  require will yield forever. The framework ships with one.
		- Global events have BOTH a RemoteEvent (for Fire) and a RemoteFunction
		  (for Invoke). Don't expect a pure one-way event; the invoke side is
		  there whether you use it or not.
		- Local events are NOT networked. Firing one on the server won't reach
		  the client, and vice versa. Use newGlobal if you need replication.
]]

local Network = {}

local signalWrapper = require(script:WaitForChild("SignalWrapper"))

-- In-process signal. No remotes, no replication. Just a callback list.
function Network.newLocal()
	return signalWrapper.newSignal()
end

-- Networked event. `name` becomes the RemoteEvent's Name under the Remotes
-- folder; a matching RemoteFunction named `<name>_Invoke` is paired with it
-- so the same event supports both Fire and Invoke styles.
function Network.newGlobal(name : string)
	local rem = signalWrapper.newRemote(name)
	-- The cast is a no-op at runtime; it just pins the inferred type so
	-- autocomplete on the returned table keeps working downstream.
	return rem :: typeof(rem)
end

return Network