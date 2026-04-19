--[[
	Bezier
	------
	Purpose:
		Smooth curve helpers for getting a point along a path defined by a list
		of Vector3s. Two flavors: "magnet" (pulled-toward path, doesn't pass
		through midpoints) and "smooth spline" (goes through every point).

	When to use:
		- Animating something along a curved path (camera paths, projectile arcs).
		- Any time you have N waypoints and want a smooth t in [0, 1] lookup.

	Example:
		local points = {p1, p2, p3, p4}
		local pos = Bezier.GetSmoothSpline(0.5, points) -- midpoint on the spline

	Gotchas:
		- `GetMagnetPath` doesn't guarantee hitting the inner control points,
		  they just "pull" the curve. Use `GetSmoothSpline` if you need to hit
		  every point.
		- `t` is expected in [0, 1]; out-of-range values will extrapolate oddly.
		- Heads up from the author: this file was mostly written with AI help.
		  The math (de Casteljau + Catmull-Rom) is standard, but double-check
		  before trusting for anything critical.
--]]

local Bezier = {}

-- Plain linear interpolation. Kept local since it's only used by the old
-- inline-math form; the public funcs use Vector3:Lerp directly.
local function lerp(a, b, t)
	return a + (b - a) * t
end

--[[
Returns a Vector3 which is between points[1] and points[n],
points[2] to [points[n-1] 'pull' the path towards them,
but doesn't guarantee passing through them.
]]
function Bezier.GetMagnetPath(t: number, points: {Vector3}): Vector3
	local n = #points
	if n < 2 then return points[1] end
	-- Two points is just a lerp, no need to run the full algorithm.
	if n == 2 then return points[1]:Lerp(points[2], t) end

	-- Clone so we don't stomp the caller's array. This is de Casteljau's
	-- algorithm: repeatedly lerp adjacent pairs until only one point remains.
	local workingPoints = {unpack(points)}

	while #workingPoints > 1 do
		for i = 1, #workingPoints - 1 do
			workingPoints[i] = workingPoints[i]:Lerp(workingPoints[i+1], t)
		end
		-- Each pass shrinks the list by one; the last slot is stale now.
		table.remove(workingPoints, #workingPoints)
	end

	return workingPoints[1]
end

--[[
Returns a Vector3 which is between points[1] and points[n],
points[2] to [points[n-1] 'pull' the path towards them,
the spline will go through every point, unlike `:GetMagnetPath()`
]]
function Bezier.GetSmoothSpline(t: number, points: {Vector3}): Vector3
	local count = #points
	if count < 2 then return points[1] end

	-- Map t in [0, 1] onto a segment index + local t within that segment,
	-- so each pair of points gets its own sub-curve.
	local p = t * (count - 1)
	local index = math.floor(p) + 1
	local localT = p - math.floor(p)

	-- Exactly at the end: return the last point to avoid an out-of-range lookup.
	if index >= count then return points[count] end

	-- Catmull-Rom needs 4 control points: previous, current, next, and the
	-- one after. Clamp at the ends so we don't walk off the array.
	local p0 = points[math.max(index - 1, 1)]
	local p1 = points[index]
	local p2 = points[index + 1]
	local p3 = points[math.min(index + 2, count)]

	-- Standard Catmull-Rom basis. Guarantees the curve passes through every
	-- input point (unlike GetMagnetPath).
	return 0.5 * (
		(2 * p1) +
			(-p0 + p2) * localT +
			(2 * p0 - 5 * p1 + 4 * p2 - p3) * localT^2 +
			(-p0 + 3 * p1 - 3 * p2 + p3) * localT^3
	)
end

return Bezier