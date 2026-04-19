local rs = game:GetService("ReplicatedStorage")

local components = script:WaitForChild("Components")
local servs = require(components:WaitForChild("Services"))
local util = require(components:WaitForChild("Util"))
local funcs = require(components:WaitForChild("Functions"))
local info = require(components:WaitForChild("Info"))

local config = require(script:WaitForChild("Config"))
local Network = require(script:WaitForChild("Network"))

local data = {
	
	---<>--- EVENTS ---<>---

	GlobalEvents = { --Network.newGlobal(name)
		VFX = Network.newGlobal("VFX"),
	},

	LocalEvents = { --Network.newLocal()
		VFX = Network.newLocal(),		
	},
	
	---<>--- SERVICES ---<>---

	Services = servs,

	---<>--- Assets ---<>---

	Assets = rs:WaitForChild("Assets"),
	Data = script:WaitForChild("Data"),

	---<>--- UTILITIES ---<>---

	Utilities = util,
	Debris = game:GetService("Debris"),

	---<> FUNCTIONS ---<>---

	Functions = funcs,

	---<> INFO ---<>---

	Info = info,

	---<>--- OTHER ---<>---

	Config = config,

	Version = "1.2.0 - Open Source, Added Utilities",
	
}

local function freeze(t : {})
	if type(t) == "table" and not table.isfrozen(t) then
		table.freeze(t)
	end	
end
for _, t : {} in data do
	freeze(t)
end
freeze(data)

return data