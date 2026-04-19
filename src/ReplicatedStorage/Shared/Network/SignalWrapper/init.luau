--[[
	SignalWrapper
	=============

	Purpose:
		Thin dispatcher that hands `Network` two factories:
			- newSignal  -> builds a local in-process signal (via SignalPlus).
			- newRemote  -> builds a networked event bound to the shared
			                `Remotes` folder that lives next to this module.

	When to use:
		You usually don't touch this directly. `Network.newLocal` and
		`Network.newGlobal` call into here. Read this file if you're
		debugging where remotes are being parented, or wiring a new event
		type in.

	Example:
		local Wrapper = require(... .SignalWrapper)
		local hitSignal = Wrapper.newSignal()            -- local
		local damageRem = Wrapper.newRemote("Damage")    -- remote

	Gotchas:
		- `par` is resolved once at require time via WaitForChild. If the
		  `Remotes` folder doesn't exist under Network, this module will yield
		  forever and the framework will never finish loading. The framework
		  ships one; don't delete it.
		- The `sig` / `rem` type aliases below use `typeof(signal())` /
		  `typeof(remote())` as a shortcut so we don't hand-write the full
		  shape of those tables.
]]

local Wrapper = {}

local signal = require(script:WaitForChild("Signal"))
local remote = require(script:WaitForChild("Remote"))

-- Type aliases pulled from the factories' return shapes. Saves us from
-- restating the signal/remote API as explicit `export type` blocks.
type sig = typeof(signal())
type rem = typeof(remote())

local network = script.Parent
-- Shared parent folder where every RemoteEvent/RemoteFunction for global
-- events ends up. One folder, many remotes, looked up by name.
local par = network:WaitForChild("Remotes")

function Wrapper.newSignal() : sig
	return signal()
end
function Wrapper.newRemote(name : string) : rem
	return remote(name, par)
end

return Wrapper