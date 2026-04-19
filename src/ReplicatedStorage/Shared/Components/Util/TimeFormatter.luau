local TimeUtil = {}

local function pad(n)
	return string.format("%02d", n)
end

-- Formats: 65 -> "1:05" or "01:05"
function TimeUtil.FormatMS(seconds: number, padMinutes: boolean)
	if seconds <= 0 then return padMinutes and "00:00" or "0:00" end
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60

	local minsStr = padMinutes and pad(mins) or tostring(mins)
	return minsStr .. ":" .. pad(secs)
end

-- Formats: 3665 -> "01:01:05" or "1:01:05"
function TimeUtil.FormatHMS(seconds: number, padHours: boolean)
	if seconds <= 0 then return "0:00:00" end
	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	local hoursStr = padHours and pad(hours) or tostring(hours)
	return hoursStr.. string.format(":%02d:%02d", mins, secs)
end

-- Formats 86465 -> "01:00:01:05" or "1:00:01:05"
function TimeUtil.FormatDHMS(seconds: number, padDays: boolean)
	if seconds <= 0 then return "0:00:00:00" end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	local daysStr = padDays and pad(days) or tostring(days)
	return daysStr.. string.format(":%02d:%02d:%02d", hours, mins, secs)
end

-- Formats: 3665 -> "1h 1m 5s", 86465 -> "1d 1m 1s"
function TimeUtil.FormatLong(seconds: number)
	if seconds <= 0 then return "0s" end

	local days = math.floor(seconds / 86400)
	local hours = math.floor((seconds % 86400) / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	local parts = {}
	if days > 0 then table.insert(parts, days .. "d") end
	if hours > 0 then table.insert(parts, hours .. "h") end
	if mins > 0 then table.insert(parts, mins .. "m") end
	if secs > 0 or #parts == 0 then table.insert(parts, secs .. "s") end

	return table.concat(parts, " ")
end

--[[
Formats 
    0 -> "00:00" or "0:00"
    30 -> "00:30" or "0:30"
    90 -> "01:30" or "1:30"
    3690 -> "01:01:30" or "1:01:30"
    86490 -> "01:00:01:30" or "1:00:01:30"
]]
function TimeUtil.SmartFormat(seconds: number, addPadding: boolean)

	local hasDays = seconds>60*60*24
	local hasHours = seconds>60*60
	local hasMinutes = seconds>60
	local isZero = seconds<=0

	if isZero then return addPadding and "00:00" or "0:00" end
	if hasDays then return TimeUtil.FormatDHMS(seconds, addPadding) end
	if hasHours then return TimeUtil.FormatHMS(seconds, addPadding) end
	if hasMinutes then return TimeUtil.FormatMS(seconds, addPadding) end

	return (addPadding and "00:" or "0:").. tostring(seconds)

end

return TimeUtil