local Network = {}

local signalWrapper = require(script:WaitForChild("SignalWrapper"))

function Network.newLocal()
	return signalWrapper.newSignal()
end

function Network.newGlobal(name : string)
	local rem = signalWrapper.newRemote(name)
	return rem :: typeof(rem)
end

return Network