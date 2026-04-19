--[[
	FormatNumber.

	Purpose:
		Turn a raw number into a short human-readable string with a K/M/B/T
		suffix. Good for currency, damage numbers, leaderboard stats.

	When to use:
		When displaying big numbers in UI and you don't want "1523456" eating
		the whole label. If you want commas instead (e.g. "1,523,456"), use
		AddCommas.

	Example:
		FormatNumber(950)       -> "950"
		FormatNumber(1500)      -> "1.5K"
		FormatNumber(2000000)   -> "2M"
		FormatNumber(-3250)     -> "-3.2K"  (sign preserved)

	Gotchas:
		- One decimal place max. A trailing ".0" gets stripped (1000 -> "1K",
		  not "1.0K"), but "1.10K" currently stays "1.10K" because the strip
		  regex only catches a single trailing zero.
		- Anything under 1000 passes through tostring unchanged; you get
		  whatever Lua prints (including scientific notation for weird floats).
]]

return function(value: number): string
	-- Ordered biggest-first so we pick the largest suffix that fits.
	local suffixes = {
		{1e12, "T"},
		{1e9, "B"},
		{1e6, "M"},
		{1e3, "K"},
	}

	-- Compare against magnitude so negatives get a suffix too (e.g. -1500 -> -1.5K).
	local absValue = math.abs(value)

	for _, data in ipairs(suffixes) do
		local divisor, suffix = data[1], data[2]
		if absValue >= divisor then
			local short = value / divisor
			local formatted = string.format("%.1f", short)
			-- Drop ".0" tail so 1000 reads "1K" instead of "1.0K".
			formatted = formatted:gsub("%.0$", "")
			return formatted .. suffix
		end
	end

	return tostring(value)
end
