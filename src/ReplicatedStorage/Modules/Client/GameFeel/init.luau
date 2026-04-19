--[[
	GameFeel

	Purpose:
		Bundle of small client-side tweaks that make movement feel nicer:
		coyote time, jump buffering, apex gravity, landing VFX. Each
		sub-module is independent and can be toggled on/off.

	When to use:
		Require once on the client, call :Init() to auto-load every
		sub-module in this folder, then flip features on via :SetEnabled,
		:Set, or :SetAll. Tune numbers with :SetConfig.

	Example:
		local GameFeel = require(path.to.GameFeel)
		GameFeel:Init()
		GameFeel:SetConfig({ CoyoteTime = 0.2 })
		GameFeel:SetEnabled({
			CoyoteTime = true,
			JumpBuffer = true,
			ApexGravity = true,
			LandingFX = true,
		})

	Gotchas:
		- Each sub-module returns a toggle function; they hold their own
		  state across enable/disable calls. Disabling only disconnects
		  events, it doesn't wipe everything.
		- ApexGravity writes to workspace.Gravity globally (see its file).
		- :SetConfig passes the shared Config table to every sub-module
		  on its next toggle; it won't live-update modules that are
		  already running. Re-toggle them to push new values.
]]

local GameFeel = {}

---<>--- Variables ---<>---

-- DefaultConfig is the source of truth for tuning knobs. Config is a
-- clone we mutate; DefaultConfig stays pristine so :SetConfig(nil) can
-- restore sane values.
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

-- Batch toggle. Any module not mentioned in `data` gets disabled, which
-- keeps this call authoritative: the table you pass is the full on/off
-- picture, not a partial patch.
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
	-- Nil argument = reset to defaults. Handy for tests or when a
	-- player changes a setting back to "default".
	if not newConfig then Config = table.clone(DefaultConfig) return end

	-- Only copy keys we already know about. Stops typos or stray fields
	-- from polluting Config and silently doing nothing.
	for i, v in newConfig do
		if Config[i] ~= nil then
			Config[i] = v
		end
	end

end

---<>--- Initialization ---<>---

-- Auto-discovers every sibling ModuleScript and stashes its toggle
-- function under the module's name. Drop a new file in the folder and
-- it'll be wired up next Init with zero extra code here.
function GameFeel:Init()

	for _, module in script:GetChildren() do
		if module:IsA("ModuleScript") then
			local toggleFunc = require(module)
			loadedMods[module.Name] = toggleFunc
		end
	end

end

return GameFeel