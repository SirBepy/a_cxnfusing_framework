local lib = table.clone(Vector3)
local extended = {}
setmetatable(extended, { __index = lib })

---<>--- Helper Functions ---<>---

local function assertVector3(val: any, name: string)
	if typeof(val) ~= "Vector3" then
		error(name .. ": Value must be a Vector3.")
	end
end

local function assertNumber(val: any, name: string)
	if typeof(val) ~= "number" then
		error(name .. ": Value must be a number.")
	end
end

---<>--- Library Functions ---<>---

--Returns the distance between two Vector3 positions.
function extended.getDistance(pos1: Vector3, pos2: Vector3): number
	assertVector3(pos1, "getDistance")
	assertVector3(pos2, "getDistance")

	return (pos1 - pos2).Magnitude
end

--Returns the normalized direction from pos1 to pos2.
function extended.getDirection(pos1: Vector3, pos2: Vector3): Vector3
	assertVector3(pos1, "getDirection")
	assertVector3(pos2, "getDirection")

	local dir = pos2 - pos1
	if dir.Magnitude == 0 then
		return Vector3.zero
	end

	return dir.Unit
end

--Returns the midpoint between two Vector3 positions.
function extended.getCenterPos(pos1: Vector3, pos2: Vector3): Vector3
	assertVector3(pos1, "getCenterPos")
	assertVector3(pos2, "getCenterPos")

	return (pos1 + pos2) / 2
end

--Rounds each component of a Vector3 to the nearest multiple of roundTo.
function extended.roundVector(vec: Vector3, roundTo: number): Vector3
	assertVector3(vec, "roundVector")
	assertNumber(roundTo, "roundVector")

	if roundTo == 0 then
		return vec
	end

	local function round(n: number): number
		return math.round(n / roundTo) * roundTo
	end

	return Vector3.new(
		round(vec.X),
		round(vec.Y),
		round(vec.Z)
	)
end

--Reflects a Vector3 off a surface normal.
function extended.reflectOffNormal(vec: Vector3, normal: Vector3): Vector3
	assertVector3(vec, "reflectOffNormal")
	assertVector3(normal, "reflectOffNormal")

	if normal.Magnitude == 0 then
		return vec
	end

	local n = normal.Unit
	return vec - 2 * vec:Dot(n) * n
end

--Sets the X component of a Vector3 to 0.
function extended.flattenX(vec: Vector3): Vector3
	assertVector3(vec, "flattenX")
	return Vector3.new(0, vec.Y, vec.Z)
end

--Sets the Y component of a Vector3 to 0.
function extended.flattenY(vec: Vector3): Vector3
	assertVector3(vec, "flattenY")
	return Vector3.new(vec.X, 0, vec.Z)
end

--Sets the Z component of a Vector3 to 0.
function extended.flattenZ(vec: Vector3): Vector3
	assertVector3(vec, "flattenZ")
	return Vector3.new(vec.X, vec.Y, 0)
end

--Returns the component of vector V1 that lies in the direction of vector V2.
function extended.project(V1: Vector3, V2: Vector3): Vector3
	assertVector3(V1, "project")
	assertVector3(V2, "project")

	if V2.Magnitude == 0 then
		return Vector3.zero
	end

	local unit = V2.Unit
	return unit * V1:Dot(unit)
end

---<>---<>---

type l2 = typeof(extended)
return extended :: l2