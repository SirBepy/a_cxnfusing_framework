--[[
	Info
	----
	Purpose:
		Registry of "state" tables that describe the current context (the local
		player, the game at large). Think of these as live, shared blackboards
		that other modules can read from without re-querying Roblox APIs.

	When to use:
		- Need the local player's Character/HRP/Humanoid from anywhere on the
		  client? Grab `Info.PlayerState`.
		- Need a shared game-wide scratchpad? Use `Info.GameState`.

	Example:
		local Info = require(Shared.Components.Info)
		local hrp = Info.PlayerState.HRP -- client only!

	Gotchas:
		- These tables are per-context. `PlayerState` only fully populates on
		  the CLIENT (there's no LocalPlayer on the server). On the server it
		  short-circuits early, so don't rely on its fields server-side.
		- Because they're shared tables, any code that mutates them affects
		  every reader. Treat them as read-mostly.
]]

return {

	GameState = require(script:WaitForChild("GameState")),
	PlayerState = require(script:WaitForChild("PlayerState")),

}
