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