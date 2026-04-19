--[[
	ExtendedLibraries
	-----------------
	Purpose:
		Aggregator that hands you drop-in replacements for Luau's built-in
		namespaces — `math`, `Random`, `table`, `Vector3` — each extended
		with extra helpers. Every original member still works; we just
		glue on more via __index so you don't lose anything.

	When to use:
		When you find yourself writing the same little helper (lerp, map,
		distance, weighted random, merge) over and over. Import the whole
		bag at the top of your script and use like the vanilla libraries.

	Example:
		local ext = require(Shared.Util.ExtendedLibraries)
		local math, Vector3, Random, table = ext.math, ext.Vector3, ext.Random, ext.table

		local mid   = Vector3.getCenterPos(a, b)
		local eased = math.map(t, 0, 1, 0, 100)
		local pick  = Random.weighted({ {value="A", weight=1}, {value="B", weight=3} })

	Gotchas:
		- These shadow the globals locally. They do NOT monkey-patch the
		  real `math`/`table` globally.
		- Each sub-module uses `setmetatable(..., {__index = lib})`. You can
		  still call vanilla methods, but new ones live on the wrapper only.
]]

return {
	math = require(script.MathExtended),
	Random = require(script.RandomExtended),
	table = require(script.TableExtended),
	Vector3 = require(script.Vector3Extended)
}