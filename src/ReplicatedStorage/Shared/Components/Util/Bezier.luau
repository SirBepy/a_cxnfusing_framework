local Bezier = {}

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
	if n == 2 then return points[1]:Lerp(points[2], t) end

	local workingPoints = {unpack(points)}

	while #workingPoints > 1 do
		for i = 1, #workingPoints - 1 do
			workingPoints[i] = workingPoints[i]:Lerp(workingPoints[i+1], t)
		end
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

	local p = t * (count - 1)
	local index = math.floor(p) + 1
	local localT = p - math.floor(p)

	if index >= count then return points[count] end

	local p0 = points[math.max(index - 1, 1)]
	local p1 = points[index]
	local p2 = points[index + 1]
	local p3 = points[math.min(index + 2, count)]

	return 0.5 * (
		(2 * p1) +
			(-p0 + p2) * localT +
			(2 * p0 - 5 * p1 + 4 * p2 - p3) * localT^2 +
			(-p0 + 3 * p1 - 3 * p2 + p3) * localT^3
	)
end

return Bezier