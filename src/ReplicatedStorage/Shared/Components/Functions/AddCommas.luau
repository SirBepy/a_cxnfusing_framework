--[[
	AddCommas.

	Purpose:
		Insert thousands-separator commas into a number. "1234567" -> "1,234,567".

	When to use:
		Long-form number display when you want every digit visible (receipts,
		detailed stat panels, debug readouts). For short labels prefer
		FormatNumber (K/M/B suffixes).

	Example:
		AddCommas(1000)     -> "1,000"
		AddCommas(1234567)  -> "1,234,567"
		AddCommas(-9876)    -> "-9,876"

	Gotchas:
		- Takes a number, returns a string. Won't stomp an existing sign.
		- Integer-oriented. Floats go through tostring first, so fractional
		  parts come along for the ride but won't get comma-formatted.
]]

return function(n: number): string
	local formatted = tostring(n)
	local k
	-- The repeat-loop is needed because gsub only walks left-to-right once,
	-- so a 7-digit number needs multiple passes to land every comma. We stop
	-- as soon as a pass makes zero replacements.
	repeat
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return formatted
end
