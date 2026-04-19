--[[
	Observer
	--------
	Purpose:
		Wraps a plain table in a userdata proxy that fires a callback whenever
		a field is written to a new value. Reads pass through to the original
		table untouched.

	When to use:
		- Reactive UI bindings (update a label when `state.Score` changes).
		- Lightweight "watch this table" without pulling in a full signal lib.

	Example:
		local data = { Score = 0 }
		local watched = Observer.new(data, function(key, val)
			print(key, "changed to", val)
		end)
		watched.Score = 5 -- prints "Score changed to 5"

	Gotchas:
		- You must write to the returned PROXY, not the original table.
		  Writing to `data.Score` directly bypasses the callback.
		- Callers often wire this into RenderStepped-driven update loops
		  (e.g. to push proxied state into UI every frame), which yields on
		  the client and won't work server-side.
		- No-op writes (same value) don't fire; intentional to avoid spam.
		- Callback runs inline with the write. If it throws, the proxy throws.
--]]

local Observer = {}
Observer.__index = Observer

export type Main = typeof(Observer)

function Observer.new(tabl: {}, callback)

	-- newproxy gives a userdata with a mutable metatable, which lets us trap
	-- writes via __newindex, something a plain table wrapper can't do cleanly.
	local proxy = newproxy(true)
	local metatable = getmetatable(proxy)

	metatable.__index = tabl
	metatable.__newindex = function(_, index, value)
		-- Skip no-op writes so the callback only fires on actual changes.
		if tabl[index] == value then return end
		tabl[index] = value
		callback(index, value)
	end

	return proxy
end

return Observer