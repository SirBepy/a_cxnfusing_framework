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

local function collectModules(root : Instance, container : {ModuleScript})
	if not root or root:HasTag(noLoadTag) then return end
	local rootType = root:GetAttribute("Type")
	if rootType and (rootType == "Client" and not isClient) or (rootType == "Server" and isClient) then return end
	
	local isNonRecursive = root:HasTag(nonRecursiveTag)

	if root:IsA("ModuleScript") then
		table.insert(container, root)
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
		if not loaded[module:GetFullName()] then
			local startTime = os.clock()
			local req = require(module)
			loaded[module:GetFullName()] = req
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

	table.sort(sortable, function(a, b)
		return (a.Priority or 0) > (b.Priority or 0)
	end)

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