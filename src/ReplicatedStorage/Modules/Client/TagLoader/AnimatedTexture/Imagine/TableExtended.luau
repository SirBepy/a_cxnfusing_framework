--[[
	TableExtended

	Purpose:
		Drop-in replacement for Luau's global `table` that adds extras
		(currently just `merge`). Real `table` methods still resolve via
		metatable fallback.

	When to use:
		Internal helper for `Imagine`. `local table = require(...)` shadows
		the stdlib in that file so `table.merge`, `table.clone`, `table.insert`
		all work off one name.

	Example:
		local t3 = table.merge({a=1,b=2}, {b=9,c=3}) -- {a=1, b=9, c=3}

	Gotchas:
		- Shadowing the global `table` is spicy but intentional; review
		  suggests renaming to `TableExt` eventually.
		- `merge` is NOT deep; nested tables are copied by reference.
		- `lib = table.clone(table)` snapshots the stdlib at require time;
		  in practice this is fine because `table` is frozen.
]]

-- Snapshot the real stdlib `table` so `extended` can fall back to it for
-- any method it doesn't explicitly define.
local lib = table.clone(table)
local extended = {}
setmetatable(extended, { __index = lib })

---<>--- Helper Functions ---<>---

local function assertTable(val: any, name: string)
	if typeof(val) ~= "table" then
		error(name .. ": Value must be a table.")
	end
end

---<>--- Library Functions ---<>---

--Returns a new table containing all values from t1, with values from t2 overriding matching keys.
function extended.merge(t1: {}, t2: {}): {}
	assertTable(t1, "merge")
	assertTable(t2, "merge")

	local result = {}

	-- copy t1
	for key, value in pairs(t1) do
		result[key] = value
	end

	-- override / add from t2
	for key, value in pairs(t2) do
		result[key] = value
	end

	return result
end

---<>---<>---

type l2 = typeof(extended)
return extended :: l2