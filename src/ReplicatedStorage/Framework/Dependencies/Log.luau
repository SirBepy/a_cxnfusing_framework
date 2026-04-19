--[[
	Log
	---
	Purpose:
		Uniform, prettified output for the framework. Wraps print/warn/error with
		a consistent banner, a [Client] or [Server] tag, and respects the toggles
		in `Shared.Config` (LogsEnabled, WarningLogsEnabled, ErrorLogsEnabled).

	When to use:
		- Any time a framework-internal module wants to surface info to a dev.
		- From user code, prefer `Framework:Log(title, info, logType)` which just
		  forwards into this function.

	Example:
		local Log = require(game:GetService("ReplicatedStorage").Framework.Dependencies.Log)
		Log("MyFeature", "did the thing", "warn")   -- yellow warning banner
		Log("MyFeature", "just info")               -- plain print, needs LogsEnabled
		Log("MyFeature", "broke!", "error")         -- raises an error (yields/halts)

	Gotchas:
		- `logType == "error"` calls `error()`, which halts the calling thread.
		- Passing nil for logType routes to plain `print`, and is gated by
		  Config.LogsEnabled.
		- Returns a single function, not a module table.
]]

local Shared = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"))
local Config = Shared.Config

local function isClient()
	return game:GetService("RunService"):IsClient()
end

local function log(title : string, info : string, logType : "warn" | "error")
	-- Early-out: if the matching Config toggle for this log level is off, stay silent.
	-- The three rows map to the three routes below (error / warn / plain print).
	if			(logType == "error" and not Config.ErrorLogsEnabled)			-- errors
		or 			(logType == "warn" and not Config.WarningLogsEnabled)		-- warnings
		or 			(not Config.LogsEnabled and not logType) 					-- prints
	then return end

	title = title or "Untitled"
	info = info or "No info."

	local printFormat = [[
	
	________________________________________________________________
	
		[Framework - %s] | [%s]
		
		%s
	
	________________________________________________________________
	]]

	local errorFormat = [[
	
	________________________________________________________________
	
		⚠️ [Framework - %s] | [%s] ⚠️
		
		%s
	
	________________________________________________________________
	]]
	
	local tag = isClient() and "Client" or "Server"
	local printFinal = string.format(printFormat, tag, title, info)
	local errorFinal = string.format(errorFormat, tag, title, info)

	if logType == "warn" then
		warn(printFinal)
	elseif logType == "error" then
		-- Stack level 3 tries to blame the caller of the caller (e.g. the user
		-- script that called Framework:Log) rather than this file itself.
		error(errorFinal, 3)
	else
		print(printFinal)
	end

end

return log