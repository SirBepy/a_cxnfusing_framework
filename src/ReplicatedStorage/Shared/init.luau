--[[
	Shared/init.luau
	----------------
	Purpose:
		The "leaf" require surface of the framework. This file mashes every
		Component (Utilities, Functions, Info, Services), the Config table,
		and every Global/Local network event into ONE table and returns it.

		`Framework` re-exports everything here, so whether you do
		`require(ReplicatedStorage.Framework)` or
		`require(ReplicatedStorage.Shared)` you get the same fields. The
		difference: Shared has zero framework-internal deps, so ModuleScripts
		that are themselves loaded BY the framework should require Shared
		(not Framework) to avoid circular requires.

	When to use:
		- From inside a module that the framework loads, require Shared.
		- From regular user Scripts/LocalScripts, require Framework instead
		  (you get the same data plus :WaitUntilLoaded / :Log / etc).

	Example:
		-- Inside a tag-loaded ModuleScript:
		local Shared = require(game.ReplicatedStorage.Shared)
		local Trove = Shared.Utilities.Trove
		Shared.GlobalEvents.VFX:FireAll("Explosion", position)

	Gotchas:
		- Both the outer `data` table AND every inner sub-table get
		  table.freeze'd at the bottom. You cannot add events/utilities at
		  runtime; edit the source and restart.
		- Adding a new Global event? Add a line under GlobalEvents here.
		  Same for LocalEvents. That registration is literally what makes
		  `Framework.GlobalEvents.YourThing` exist.
		- `Assets` and `Data` use WaitForChild, so if you haven't put an
		  `Assets` folder under ReplicatedStorage (and a `Data` folder
		  under Shared) this require will yield forever. Make them or
		  delete the lines.
]]

local rs = game:GetService("ReplicatedStorage")

-- Each sub-folder has its own init.luau that aggregates its children.
-- We just require them in and slot them into `data` below.
local components = script:WaitForChild("Components")
local servs = require(components:WaitForChild("Services"))
local util = require(components:WaitForChild("Util"))
local funcs = require(components:WaitForChild("Functions"))
local info = require(components:WaitForChild("Info"))

local config = require(script:WaitForChild("Config"))
local Network = require(script:WaitForChild("Network"))

local data = {

	---<>--- EVENTS ---<>---

	-- Server<->Client events. Wrap a RemoteEvent so both sides share one
	-- name. To add one: `MyThing = Network.newGlobal("MyThing")`.
	GlobalEvents = { --Network.newGlobal(name)
		VFX = Network.newGlobal("VFX"),
	},

	-- Same-process signals (no networking). Use these when you want
	-- different scripts on the SAME side to talk without a RemoteEvent.
	LocalEvents = { --Network.newLocal()
		VFX = Network.newLocal(),
	},

	---<>--- SERVICES ---<>---

	-- Both roblox services (Players, ReplicatedStorage, ...) and framework
	-- services (VFX, DataService) live in here. See Components/Services.
	Services = servs,

	---<>--- Assets ---<>---

	-- Project-wide asset folder. You'll want a ReplicatedStorage.Assets
	-- folder in your place or this line yields forever.
	Assets = rs:WaitForChild("Assets"),
	-- Optional Data folder sibling to this init for static data modules.
	-- Remove this line if you don't use it (it also yields if missing).
	Data = script:WaitForChild("Data"),

	---<>--- UTILITIES ---<>---

	-- Giant grab-bag: Bezier, Trove, Pool, CameraShaker, Spring, ...
	-- See Components/Util for the list.
	Utilities = util,
	-- Exposed at the top level for convenience; it's used enough that
	-- typing `Framework.Debris` is nicer than reaching through Services.
	Debris = game:GetService("Debris"),

	---<> FUNCTIONS ---<>---

	-- Small pure-ish helpers (FastTween, FormatNumber, AddCommas, ...).
	-- "Functions" are one-shot call-and-forget; "Utilities" are bigger or
	-- stateful. That's the only real distinction.
	Functions = funcs,

	---<> INFO ---<>---

	-- Shared state tables (PlayerState, GameState). Read/write these to
	-- share context between modules on the same side.
	Info = info,

	---<>--- OTHER ---<>---

	Config = config,

	-- Bump me when you cut a release. Surfaced as Framework.Version.
	Version = "1.2.0 - Open Source, Added Utilities",

}

-- Defensive freeze: we don't want user code to accidentally add/remove
-- fields on the shared surface at runtime (that'd make it impossible for
-- other scripts to rely on the layout). `isfrozen` check lets us skip
-- tables that came in already frozen from their own module.
local function freeze(t : {})
	if type(t) == "table" and not table.isfrozen(t) then
		table.freeze(t)
	end
end
-- Freeze each inner table first (Events, Services, etc), then the outer
-- `data` table itself. Note: signal-shaped tables inside Events still
-- need to mutate their connection lists, so in practice Network.*
-- returns objects (not plain tables) that are safe to "freeze".
for _, t : {} in data do
	freeze(t)
end
freeze(data)

return data