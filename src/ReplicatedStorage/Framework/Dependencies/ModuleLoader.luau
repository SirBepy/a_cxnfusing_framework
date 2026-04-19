--[[
	ModuleLoader
	------------
	Purpose:
		Walks Instance trees, requires every ModuleScript it finds, then later
		runs :Init() on all of them followed by :Start() on all of them. Also
		hooks the `LoadModule` CollectionService tag so modules can be discovered
		by tagging an Instance in Studio instead of parenting it to a known folder.

	When to use:
		- You almost never call this directly. `Framework/init.luau` drives it.
		- If you are adding a new root folder of modules, call `:RequireAll(folder)`
		  before `:LoadAll()`.

	Example:
		local Loader = require(script.Parent:WaitForChild("Dependencies"):WaitForChild("ModuleLoader"))
		Loader:RequireAll(workspace.MyStuff)
		Loader:LoadAll()

	Tags + attributes this respects (put on the ModuleScript or a container):
		- Tag "LoadModule"    -> discovered via :RequireTagged().
		- Tag "NonRecursive"  -> require this module, but do not walk its descendants.
		- Tag "NoLoad"        -> skip this instance *and* its whole subtree.
		- Attribute "Type"    -> "Client" means client-only, "Server" means server-only.
		                         Also works on *container* folders: a folder with
		                         Type="Server" will silently skip the whole subtree
		                         on the client. (This is the single most surprising
		                         behavior here.)

	Module conventions this expects:
		- The required module should return a table.
		- Optional `Priority` field (number). Higher runs earlier during both
		  the Init pass and the Start pass. Missing = 0.
		- Optional `:Init(self)` method, called first across all modules.
		- Optional `:Start(self)` method, called after every Init has finished.

	Gotchas:
		- Yields: `:RequireAll` yields while each ModuleScript is required.
		- `:LoadAll` is really meant to be called once. Calling it again re-runs
		  :Init and :Start on every module that has been required so far.
		- A module tagged after `:LoadAll` has already finished will be required
		  but its :Init/:Start are NOT re-invoked.
]]

local Loader = {}

local loaded = {}
local requiredModules = {}

local Shared = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"))

local isClient = game:GetService("RunService"):IsClient()

local Log = require(script.Parent:WaitForChild("Log"))
local Config = Shared.Config

local nonRecursiveTag = "NonRecursive"
local noLoadTag = "NoLoad"
local loadTag = "LoadModule"

-- Recursive walker. Fills `container` with every ModuleScript under `root`
-- that passes the tag/attribute filters. Containers (Folders, etc.) with the
-- wrong Type attribute will cut off their entire subtree here.
local function collectModules(root : Instance, container : {ModuleScript})
	if not root or root:HasTag(noLoadTag) then return end
	local rootType = root:GetAttribute("Type")
	-- Skip instances marked for the other side of the network boundary.
	if rootType and (rootType == "Client" and not isClient) or (rootType == "Server" and isClient) then return end

	local isNonRecursive = root:HasTag(nonRecursiveTag)

	if root:IsA("ModuleScript") then
		table.insert(container, root)
		-- NonRecursive: include this module but don't descend into its children.
		-- Useful when a ModuleScript has sub-ModuleScripts that are helpers, not
		-- lifecycle-managed modules.
		if isNonRecursive then return end
	end

	for _, child in ipairs(root:GetChildren()) do
		collectModules(child, container)
	end
end

function Loader:RequireAll(root : Instance)
	if not root then return end

	local modulesToLoad = {}
	collectModules(root, modulesToLoad)

	for _, module : ModuleScript in ipairs(modulesToLoad) do
		-- Dedupe by full path so overlapping root folders don't require twice.
		if not loaded[module:GetFullName()] then
			local startTime = os.clock()
			local req = require(module)
			loaded[module:GetFullName()] = req
			-- Stash the require result + timing so LoadAll can sort and report later.
			table.insert(requiredModules, {
				Instance = module,
				Table = req,
				LoadTime = (os.clock() - startTime) * 1000,
			})
		end
	end
end

function Loader:LoadAll()

	local sortable = {}
	for _, data in ipairs(requiredModules) do
		if type(data.Table) == "table" then
			table.insert(sortable, data.Table)
		end
	end

	-- Higher Priority runs earlier. Missing Priority is treated as 0, so anything
	-- that wants to load before the default pack just sets a positive number.
	table.sort(sortable, function(a, b)
		return (a.Priority or 0) > (b.Priority or 0)
	end)

	-- Two-phase lifecycle: every :Init() runs before any :Start() runs, so a
	-- module's Start can safely assume sibling modules have finished their Init.
	for _, module in ipairs(sortable) do
		if module.Init then
			module:Init()
		end
	end

	for _, module in ipairs(sortable) do
		if module.Start then
			module:Start()
		end
	end

	if Config.LogModuleLoadTimes then
		for _, data in ipairs(requiredModules) do
			Log(
				"Module Loader",
				string.format(
					"⏱️ '%s': Loaded in %.2f ms",
					data.Instance.Name,
					data.LoadTime
				)
			)
		end
	end
end

function Loader:RequireTagged()
	Shared.Utilities.ConnectToTag(loadTag, function(mod : ModuleScript)
		Loader:RequireAll(mod)
	end)
end

function Loader:GetLoaded()
	return loaded
end

return Loader