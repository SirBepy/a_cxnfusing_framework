--[[
	TagLoader

	Purpose:
		Auto-wires each child ModuleScript to a CollectionService tag so any
		instance tagged with that name gets the module's function called on it.

	When to use:
		Drop a ModuleScript in here that returns `function(obj) ... end`. Any
		instance tagged with the module's filename runs through it automatically
		(existing instances + future ones). Good for attribute-driven UI setup,
		animated textures, etc.

	Contract (IMPORTANT):
		- The module's FILENAME is used verbatim as the CollectionService tag.
		  e.g. `UIAnimate.luau` binds tag "UIAnimate". No manifest, no registry.
		- The module must return a single function: `(obj: Instance) -> ()`.

	Example:
		-- File: ReplicatedStorage/Modules/Client/TagLoader/MyThing.luau
		return function(obj)
			print("tagged:", obj:GetFullName())
		end
		-- Then in Studio, add the "MyThing" tag to any instance.

	Gotchas:
		- Filename == tag name. Rename the file, rename every tag in game.
		- `Preset` runs first on purpose (it resolves the "Preset" attribute
		  into real attributes before other modules read them).
		- No teardown: connections from `ConnectToTag` live for the session.
		- Child folders / non-ModuleScripts will error on `require`; keep this
		  folder flat with only ModuleScripts (plus `Preset`'s nested folder).
]]

local TagLoader = {}

local rs = game:GetService("ReplicatedStorage")
local Shared = require(rs:WaitForChild("Shared"))

-- Dedupe guard: `:Start` pre-calls Preset then iterates all children, so
-- Preset would bind twice without this.
local loaded = {}

local function initTag(mod : ModuleScript)
	if loaded[mod] then return end
	loaded[mod] = true

	local req = require(mod)
	-- `mod.Name` IS the tag. Filename-as-tag contract lives here.
	Shared.Utilities.ConnectToTag(mod.Name, function(obj)
		req(obj)
	end)

end

function TagLoader:Start()
	-- Preset first so attribute expansion happens before any other tag
	-- module reads attributes off the same instance.
	initTag(script:WaitForChild("Preset"))
	for _, mod in script:GetChildren() do
		initTag(mod)
	end
end

return TagLoader