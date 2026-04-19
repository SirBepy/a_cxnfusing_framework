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
		storedActions[actionName] = 0 
	end

	return isActive
end

function ActionBuffer:Clear(actionName: string)
	storedActions[actionName] = nil
end

return ActionBuffer