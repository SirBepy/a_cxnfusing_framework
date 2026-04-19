local Wrapper = {}

local signal = require(script:WaitForChild("Signal"))
local remote = require(script:WaitForChild("Remote"))

type sig = typeof(signal())
type rem = typeof(remote())

local network = script.Parent
local par = network:WaitForChild("Remotes")

function Wrapper.newSignal() : sig
	return signal()
end
function Wrapper.newRemote(name : string) : rem
	return remote(name, par)
end

return Wrapper