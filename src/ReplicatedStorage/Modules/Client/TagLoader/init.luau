local TagLoader = {}

local rs = game:GetService("ReplicatedStorage")
local Shared = require(rs:WaitForChild("Shared"))

local loaded = {}

local function initTag(mod : ModuleScript)
	if loaded[mod] then return end
	loaded[mod] = true

	local req = require(mod)
	Shared.Utilities.ConnectToTag(mod.Name, function(obj)
		req(obj)
	end)

end

function TagLoader:Start()
	initTag(script:WaitForChild("Preset"))
	for _, mod in script:GetChildren() do
		initTag(mod)
	end
end

return TagLoader