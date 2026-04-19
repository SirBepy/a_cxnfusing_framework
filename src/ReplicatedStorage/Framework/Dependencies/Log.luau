local Shared = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"))
local Config = Shared.Config

local function isClient()
	return game:GetService("RunService"):IsClient()
end

local function log(title : string, info : string, logType : "warn" | "error")
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
		error(errorFinal, 3)
	else
		print(printFinal)		
	end

end

return log