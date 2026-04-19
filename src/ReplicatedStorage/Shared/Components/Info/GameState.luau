--[[
	GameState
	---------
	Purpose:
		Shared, game-wide scratchpad table. Anything that multiple systems
		need to read/write about the overall game session (current round,
		match phase, global modifiers, etc.) lives here.

	When to use:
		- You've got state that isn't tied to a single player and isn't worth
		  spinning up a whole service for. Drop it on GameState.
		- Read it from anywhere: `Info.GameState.CurrentRound = 3`.

	Example:
		local GameState = require(Shared.Components.Info).GameState
		GameState.Phase = "Intermission"

	Gotchas:
		- Currently empty by design - fields are added ad-hoc by whatever
		  system owns the concept. Expect it to grow.
		- The trailing `:: { ... }` block below is an intentional type-cast
		  shape used by the framework; don't "fix" it without updating the
		  callers that rely on the annotation.
		- Shared mutable table: no replication magic here. If you need the
		  value on both client and server, wire it through Network yourself.
]]

return {

}
::
{

}
