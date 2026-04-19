local rs = game:GetService("ReplicatedStorage")
local sss = game:GetService("ServerScriptService")

local rsMods = rs:WaitForChild("Modules")
local Shared = require(rs:WaitForChild("Shared"))

local dependencies = script:WaitForChild("Dependencies")
local ModuleLoader = require(dependencies:WaitForChild("ModuleLoader"))
local Log = require(dependencies:WaitForChild("Log"))

local Framework = {

	---<>--- EVENTS ---<>---

	GlobalEvents = Shared.GlobalEvents,
	LocalEvents = Shared.LocalEvents,

	---<>--- SERVICES ---<>---

	Services = Shared.Services,

	---<>--- Assets ---<>---
	
	Assets = Shared.Assets,
	Data = Shared.Data,
	
	---<>--- UTILITIES ---<>---

	Utilities = Shared.Utilities,
	Debris = Shared.Debris,

	---<> FUNCTIONS ---<>---

	Functions = Shared.Functions,

	---<> INFO ---<>---

	Info = Shared.Info,

	---<>--- MODULES (no Intellisense) ---<>---

	LoadedModules = {},

	---<>--- OTHER ---<>---

	Config = Shared.Config,
	
	Version = Shared.Version,
	
	Loaded = false,
	OnLoaded = Shared.Utilities.Signal(),

}

---<>--- General Helpers ---<>---

function Framework:IsServer()
	return Framework.Services.RunService:IsServer()
end

function Framework:IsClient()
	return Framework.Services.RunService:IsClient()
end

function Framework:IsStudio()
	return Framework.Services.RunService:IsStudio()
end

---<>--- Useful Utilities ---<>---

function Framework:Log(title : string, info : string, logType : "warn" | "error")
	return Log(title, info, logType)
end

function Framework:SafeCall(func : (any)->(any))
	return Framework.Utilities.DebugUtils.SafeCall(func)
end

function Framework:Preload(IDs : {number}, callback : ()->())
	Framework.Services.ContentProvider:PreloadAsync(IDs, callback)
end

function Framework:WaitUntilLoaded()
	if Framework.Loaded then return end
	Framework.OnLoaded:Wait()
end

---<>--- Module Loading ---<>---

local startTime = os.clock()
local toLoad = {}

if Framework:IsClient() then
	toLoad = {rsMods:WaitForChild("Client"), rsMods:WaitForChild("Combined")}
else
	toLoad = {sss.Modules, sss.Services, rsMods.Combined}
end

for _, folder in toLoad do
	ModuleLoader:RequireAll(folder)
end

ModuleLoader:RequireTagged()
ModuleLoader:LoadAll()

Framework.LoadedModules = ModuleLoader:GetLoaded()

---<>--- Freezing ---<>---

local function freeze(t : {})
	if type(t) == "table" and not table.isfrozen(t) then
		table.freeze(t)
	end	
end
for _, t : {} in Framework do
	if type(t) == "table" and t.Fire and t.Connect then continue end
	freeze(t)
end
--freeze(Framework)

---<>--- Loading Prints ---<>---

if Framework.Services.RunService:IsClient() then
	Framework:Log(
		"Main",
		[[✅ Client framework loaded.]]..
			string.format([[
			
		📄 Current version: %s]], Framework.Version)..
			string.format([[
			
		⏱️ Time taken: %.2f ms]], (os.clock()-startTime)*1000),
		"warn"
	)	
else
	Framework:Log(
		"Main",
		[[✅ Server framework loaded]]..
			string.format([[
			
		📄 Current version: %s]], Framework.Version)..
			string.format([[
			
		⏱️ Time taken: %.2f ms]], (os.clock()-startTime)*1000),
		"warn"
	)
end

Framework.Loaded = true
Framework.OnLoaded:Fire(os.clock()-startTime)

return Framework