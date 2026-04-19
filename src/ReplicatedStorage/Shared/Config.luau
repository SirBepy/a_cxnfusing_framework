--[[
	Config.luau
	-----------
	Purpose:
		One tiny table of flags the framework reads at runtime. Toggle stuff
		here instead of hunting through source. Reachable as
		`Framework.Config` (or `Shared.Config`).

	When to use:
		- Flip log verbosity on/off while debugging.
		- Add your own game-wide flags under the "Game Config" section
		  (difficulty, feature gates, debug cheats, etc).

	Example:
		local Framework = require(game.ReplicatedStorage.Framework)
		if Framework.Config.LogsEnabled then
			print("logs are on")
		end

	Gotchas:
		- This table gets frozen by `Shared/init.luau`, so you can't mutate
		  it at runtime. Edit the source file and restart instead.
		- The three log flags are independent booleans right now; there's no
		  single "log level" switch.
]]

return {

	---<>--- Game Config ---<>---

	-- Add your own game-specific flags here (e.g. DebugMode = true).


	---<>--- Framework Config ---<>---

	-- Gate normal prints coming out of the framework / your own Log calls.
	LogsEnabled = true,
	-- Gate warn-level output. Usually leave on; warnings mean something's off.
	WarningLogsEnabled = true,
	-- Gate error-level output. Leave on unless you really want silence.
	ErrorLogsEnabled = true,

	-- When true, ModuleLoader prints how long each module's Init/Start took.
	-- Handy for spotting a module that's blowing your load budget.
	LogModuleLoadTimes = true,

}
