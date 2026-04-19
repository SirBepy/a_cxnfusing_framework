--[[
	ActionBuffer
	------------
	Purpose:
		Tiny input-buffering helper. Record that an action happened, then check
		a moment later whether it's still "fresh" enough to act on. Lets you
		forgive slightly-early inputs (pressing jump right before landing, for
		example) without sprinkling timestamps everywhere.

	When to use:
		- Combat/movement input that should feel lenient: buffer the press now,
		  consume it when the gameplay condition becomes valid.
		- Any "did X happen in the last N seconds?" check.

	API:
		:Record(actionName)                      -- stamp an action as having just happened
		:IsActive(actionName, customWindow?)     -- returns true if it's still within the buffer window (default 0.2s); consuming on hit
		:Clear(actionName)                       -- wipe an entry

	Example:
		local ActionBuffer = require(path.to.ActionBuffer)

		-- on input:
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.KeyCode == Enum.KeyCode.Space then
				ActionBuffer:Record("Jump")
			end
		end)

		-- in your movement step, when landing becomes true:
		if landed and ActionBuffer:IsActive("Jump") then
			character:Jump()
		end

		-- custom window (say you want 0.35s of leniency for dash):
		if ActionBuffer:IsActive("Dash", 0.35) then ... end

	Gotchas:
		- :IsActive is consuming on a hit: it resets the timestamp so a single
		  Record can't satisfy two IsActive checks. Treat it as "try consume".
		- The storage is module-global (shared across all requirers). Namespace
		  your actionName strings if multiple systems share it.
		- Default window is 200ms. Pass customWindow if you want something
		  tighter or looser per-call.
]]

local ActionBuffer = {}
local storedActions = {}

local EXPIRE_TIME = 0.2

function ActionBuffer:Record(actionName: string)
	storedActions[actionName] = os.clock()
end

function ActionBuffer:IsActive(actionName: string, customWindow: number?)
	local timestamp = storedActions[actionName]
	if not timestamp then return false end

	local window = customWindow or EXPIRE_TIME
	local isActive = (os.clock() - timestamp) <= window

	if isActive then
		-- Consume-on-hit: zeroing the timestamp makes future checks stale
		-- (os.clock() - 0 is huge, so it won't pass the window test), which
		-- prevents one Record from satisfying multiple IsActive calls.
		storedActions[actionName] = 0
	end

	return isActive
end

function ActionBuffer:Clear(actionName: string)
	storedActions[actionName] = nil
end

return ActionBuffer
