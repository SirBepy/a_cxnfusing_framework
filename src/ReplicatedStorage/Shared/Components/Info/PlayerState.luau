--[[
	PlayerState
	-----------
	Purpose:
		Live snapshot of the LOCAL player's character. Keeps `Character`,
		`HRP`, and `Humanoid` up to date across respawns so client code can
		just read `PlayerState.HRP` instead of chasing CharacterAdded itself.

	When to use:
		- Any client-side script that needs quick access to the local
		  character/HRP/humanoid without wiring its own CharacterAdded hook.
		- Listen to `PlayerState.CharacterAdded:Connect(fn)` if you need to
		  react to respawns (fires AFTER the fields above are refreshed, so
		  the signal handler sees the new character).

	Example:
		local PlayerState = require(Shared.Components.Info).PlayerState
		print(PlayerState.Humanoid.Health)

		PlayerState.CharacterAdded:Connect(function(chr)
			print("respawned as", chr.Name)
		end)

	Gotchas:
		- CLIENT ONLY. On the server this module returns `true` early (see
		  line 4), so indexing fields server-side will crash. Guard with
		  RunService:IsClient() if you're in shared code.
		- `Connections` is an empty table reserved for future per-character
		  cleanup; nothing populates it today.
		- The CharacterAdded signal here is the framework's own Signal, NOT
		  `plr.CharacterAdded`. It fires with the refreshed character after
		  HRP/Humanoid have been re-waited-for.
]]

local plr = game.Players.LocalPlayer
local signal = require(script.Parent.Parent.Util).Signal

-- Bail on the server: there is no LocalPlayer, so the rest of this file
-- would error. Returning `true` here keeps the require chain happy while
-- making server-side misuse fail loudly on the first field access.
if not game:GetService("RunService"):IsClient() then return true :: data end

type signal = typeof(signal())
type data = {

	Character : Model,
	CharacterAdded : signal,

	HRP : BasePart,
	Humanoid : Humanoid,

	Connections : {[string] : RBXScriptConnection},

}

local data = {

	Character = plr.Character,
	CharacterAdded = signal(),

	Connections = {},

}::data

-- First-load: character may or may not exist yet depending on when this
-- module is first required, so wait it out if needed.
data.Character = plr.Character or plr.CharacterAdded:Wait()
data.HRP = data.Character:WaitForChild("HumanoidRootPart")
data.Humanoid = data.Character:WaitForChild("Humanoid")

-- Keep the snapshot in sync on every respawn. Important: we refresh HRP
-- and Humanoid BEFORE firing our own signal so listeners see a fully-
-- populated state, not a half-swapped one.
plr.CharacterAdded:Connect(function(chr)

	data.Character = chr
	data.HRP = chr:WaitForChild("HumanoidRootPart")
	data.Humanoid = chr:WaitForChild("Humanoid")

	data.CharacterAdded:Fire(chr)

end)

return data
