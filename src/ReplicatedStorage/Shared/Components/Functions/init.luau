--[[
	Functions registry.

	Purpose:
		Tiny, pure-ish helpers that don't need classes or state. If a helper
		fits on a napkin and just takes input -> output, it lives here.

	When to use:
		Reach into Functions for formatting, tweening shortcuts, UID generation,
		etc. If your helper needs lifecycle, signals, or instance tracking,
		it probably belongs in Util/ instead.

	Example:
		local Shared = require(ReplicatedStorage.Shared)
		local pretty = Shared.Functions.FormatNumber(1250000) -- "1.2M"

	Gotchas:
		- Adding a new helper? Drop the file next to this one and add a require
		  line below. Don't forget to match the style of the other entries.
		- This table gets frozen upstream, so don't mutate it at runtime.
]]

return {

	FastTween = require(script:WaitForChild("FastTween")),

	FormatNumber = require(script:WaitForChild("FormatNumber")),
	AddCommas = require(script:WaitForChild("AddCommas")),

	GenerateUID = require(script:WaitForChild("GenerateUID")),

}
