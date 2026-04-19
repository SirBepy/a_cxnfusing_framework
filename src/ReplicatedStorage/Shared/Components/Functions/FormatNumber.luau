return function(value: number): string
	local suffixes = {
		{1e12, "T"},
		{1e9, "B"},
		{1e6, "M"},
		{1e3, "K"},
	}

	local absValue = math.abs(value)

	for _, data in ipairs(suffixes) do
		local divisor, suffix = data[1], data[2]
		if absValue >= divisor then
			local short = value / divisor
			local formatted = string.format("%.1f", short)
			formatted = formatted:gsub("%.0$", "")
			return formatted .. suffix
		end
	end

	return tostring(value)
end