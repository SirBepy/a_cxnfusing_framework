--[[
	MathExtended — namespace-extension for Luau's `math`
	----------------------------------------------------
	Purpose:
		Rounding to a step, averaging, lerp / inverseLerp / map (like
		Unity's Mathf), and angle normalization. Bread-and-butter helpers
		the built-in math library is missing.

	When to use:
		Tween math, remapping ranges (e.g. input 0-1 to UI pixels),
		snapping to grids, any time you want to shorten a common formula.

	Example:
		local math = require(Shared.Util.ExtendedLibraries).math
		local percent = math.inverseLerp(0, 100, 37)  -- 0.37
		local pixels  = math.map(percent, 0, 1, 0, 500)
		local snapped = math.roundToNearest(value, 0.25)

	Gotchas:
		- map returns outMin if inMin == inMax (no divide-by-zero, but no
		  interpolation either).
		- All helpers assert and throw on non-numbers; wrap in pcall if you
		  want forgiving behavior.
]]

-- Clone vanilla `math` and fall back through the metatable so math.pi,
-- math.random, etc. still work on the extended table.
local lib = table.clone(math)
local extended = {}
setmetatable(extended, { __index = lib })

---<>--- Helper Functions ---<>---

local function assertNumber(val: any, name: string)
	if typeof(val) ~= "number" then
		error(name .. ": Value must be a number.")
	end
end

---<>--- Library Functions ---<>---

--Returns the nearest multiple of step to value.
function extended.roundToNearest(value: number, step: number): number
	assertNumber(value, "roundToNearest")
	assertNumber(step, "roundToNearest")

	if step == 0 then return value end
	return math.round(value / step) * step
end

--Returns the smallest multiple of step greater than or equal to value.
function extended.ceilToNearest(value: number, step: number): number
	assertNumber(value, "ceilToNearest")
	assertNumber(step, "ceilToNearest")

	if step == 0 then return value end
	return math.ceil(value / step) * step
end

--Returns the largest multiple of step less than or equal to value.
function extended.floorToNearest(value: number, step: number): number
	assertNumber(value, "floorToNearest")
	assertNumber(step, "floorToNearest")

	if step == 0 then return value end
	return math.floor(value / step) * step
end

--Returns the average of all numeric arguments.
function extended.average(...: number): number
	local sum = 0
	local count = 0

	for _, value in { ... } do
		assertNumber(value, "average")
		sum += value
		count += 1
	end

	if count == 0 then
		error("average: No values provided.")
	end

	return sum / count
end

--Returns the value t (0–1) percent from a to b.
function extended.lerp(a: number, b: number, t: number): number
	assertNumber(a, "lerp")
	assertNumber(b, "lerp")
	assertNumber(t, "lerp")

	return a + (b - a) * t
end

--Returns how far val lies between a and b (0–1).
function extended.inverseLerp(a: number, b: number, val: number): number
	assertNumber(a, "inverseLerp")
	assertNumber(b, "inverseLerp")
	assertNumber(val, "inverseLerp")

	if a == b then return 0 end
	return (val - a) / (b - a)
end

--Maps val from range [inMin, inMax] to [outMin, outMax].
function extended.map(
	val: number,
	inMin: number,
	inMax: number,
	outMin: number,
	outMax: number
): number
	assertNumber(val, "map")
	assertNumber(inMin, "map")
	assertNumber(inMax, "map")
	assertNumber(outMin, "map")
	assertNumber(outMax, "map")

	if inMin == inMax then
		return outMin
	end

	local t = extended.inverseLerp(inMin, inMax, val)
	return extended.lerp(outMin, outMax, t)
end

--Normalizes an angle to [0-360] range
-- The double-mod trick handles negative inputs: e.g. -30 % 360 = 330 on Luau,
-- but we add 360 then mod again to be safe across engines/number quirks.
function extended.normalizeAngle(angle : number)
	return (angle % 360 + 360) % 360
end

---<>---<>---

type l2 = typeof(extended)
return extended :: l2