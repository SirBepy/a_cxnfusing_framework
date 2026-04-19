local GameFeel = {}

---<>--- Variables ---<>---

local DefaultConfig = {

	JumpBufferTime = 0.12,
	
	CoyoteTime = 0.15,

	ApexGravityMultiplier = 0.5,
	ApexGravityMinVelocity = 12,

	LandingFXMinHeight = 10,

}

local Config = table.clone(DefaultConfig)

local loadedMods = {}

---<>--- Main Functions ---<>---

function GameFeel:SetEnabled(data : {[string] : boolean})

	for modName, toggleFunc in loadedMods do
		if data[modName] ~= nil then
			toggleFunc(data[modName], Config)
		else
			toggleFunc(false, Config)
		end
	end

end

function GameFeel:Set(modName : string, enabled : boolean)

	if loadedMods[modName] then
		loadedMods[modName](enabled, Config)
	end

end

function GameFeel:SetAll(enabled : boolean)
	
	for modName, toggleFunc in loadedMods do
		toggleFunc(enabled, Config)
	end
	
end

function GameFeel:SetConfig(newConfig : {

	JumpBufferTime : number,
	
	CoyoteTime : number,

	ApexGravityMultiplier : number,
	ApexGravityMinVelocity : number,

	LandingFXMinHeight : number,

	})
	if not newConfig then Config = table.clone(DefaultConfig) return end

	for i, v in newConfig do
		if Config[i] ~= nil then
			Config[i] = v
		end
	end

end

---<>--- Initialization ---<>---

function GameFeel:Init()

	for _, module in script:GetChildren() do
		if module:IsA("ModuleScript") then
			local toggleFunc = require(module)
			loadedMods[module.Name] = toggleFunc
		end
	end

end

return GameFeel