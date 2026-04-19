--[[
	Framework (the loader)
	----------------------
	Purpose:
		The main entry point. Requires `Shared` (the leaf data surface), then walks
		the `Modules` folders, requires every ModuleScript, and runs their
		:Init() / :Start() lifecycle methods. Exposes utilities, events, services,
		and helpers all under one table.

	When to use:
		- From a regular Script or LocalScript that wants the "everything" table.
		- Any time you need :WaitUntilLoaded, :Log, :SafeCall, :IsServer/IsClient,
		  or the loaded modules map.
		- Pair with `Shared` (require that one from ModuleScripts that are themselves
		  loaded *by* the framework, to avoid circular requires).

	Example:
		local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))
		Framework:WaitUntilLoaded()
		Framework:Log("MyScript", "hello world", "warn")

	Gotchas:
		- Requiring this file triggers the full module load pipeline. Do it once
		  per context (one Script server-side, one LocalScript client-side).
		- The inner tables are `table.freeze`d before return (signal-like tables
		  are skipped). Do not try to mutate Framework.Utilities at runtime.
		- Server pulls from ServerScriptService.Modules/Services + RS.Modules.Combined.
		  Client pulls from RS.Modules.Client + RS.Modules.Combined.
]]

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

	-- Filled in after ModuleLoader runs. Keyed by module:GetFullName(), value is
	-- whatever the module returned. No autocomplete because the keys are dynamic.
	LoadedModules = {},

	---<>--- OTHER ---<>---

	Config = Shared.Config,
	
	Version = Shared.Version,
	
	-- Loaded flips true once every module's :Init() and :Start() have finished.
	-- OnLoaded fires exactly once with the total load time in seconds as the payload.
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

-- Yields the calling thread until the framework has finished loading every module.
-- Safe to call after loading has already finished; returns immediately in that case.
function Framework:WaitUntilLoaded()
	if Framework.Loaded then return end
	Framework.OnLoaded:Wait()
end

---<>--- Module Loading ---<>---

local startTime = os.clock()
local toLoad = {}

-- Pick which folders to crawl based on context. "Combined" is shared between
-- client and server, so both sides include it.
if Framework:IsClient() then
	toLoad = {rsMods:WaitForChild("Client"), rsMods:WaitForChild("Combined")}
else
	toLoad = {sss.Modules, sss.Services, rsMods.Combined}
end

for _, folder in toLoad do
	ModuleLoader:RequireAll(folder)
end

-- Hook CollectionService so anything tagged `LoadModule` later gets required too,
-- then kick off :Init() and :Start() on everything we've collected so far.
ModuleLoader:RequireTagged()
ModuleLoader:LoadAll()

Framework.LoadedModules = ModuleLoader:GetLoaded()

---<>--- Freezing ---<>---

local function freeze(t : {})
	if type(t) == "table" and not table.isfrozen(t) then
		table.freeze(t)
	end	
end
-- Freeze inner tables so downstream code can't accidentally mutate shared state.
-- Signal-like tables (anything with both Fire and Connect) are skipped because
-- they need to mutate their internal connection list to work.
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