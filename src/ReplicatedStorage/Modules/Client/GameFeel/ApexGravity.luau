--[[
	ApexGravity

	Purpose:
		"Apex gravity" is the trick of lowering gravity right at the
		top of a jump, the moment where the player is nearly weightless
		anyway. Makes jumps feel floatier and gives more hang-time at
		the peak without making the whole jump feel slow.

	When to use:
		Enable via GameFeel when you want snappy jumps that still feel
		satisfying at the top. Tune ApexGravityMultiplier (how much
		gravity drops at the apex, e.g. 0.5 = half) and
		ApexGravityMinVelocity (how close to zero Y-velocity counts as
		"the apex").

	Example:
		GameFeel:Set("ApexGravity", true)

	Gotchas:
		- This module mutates workspace.Gravity GLOBALLY every frame
		  while active. If anything else in your game reads or writes
		  workspace.Gravity, it will fight with this module. The
		  original value is snapshotted at require time, so if gravity
		  was changed before then, "restore" means restoring to that
		  snapshot, not to Roblox's default 196.2.
		- Runs on Heartbeat, so the effect is purely client-side visual
		  for the LocalPlayer; other players won't see the altered
		  gravity.
]]

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local hum : Humanoid = chr:WaitForChild("Humanoid")
local hrp : BasePart = chr.PrimaryPart

local uis = game:GetService("UserInputService")

local config = {
	ApexGravityMultiplier = 0.5,
	ApexGravityMinVelocity = 12
}

-- Snapshot the current gravity at module-load so we can restore it
-- between apex moments. Note: whatever workspace.Gravity is at require
-- time becomes our "normal".
local origGravity = workspace.Gravity

local conns = {}

local function isAlive()
	if not hum or hum.Health <= 0 or not hrp then return end
	return true
end

local function upd()
	if not isAlive() then return end
	-- Airborne AND vertical speed is low = we're near the peak of the
	-- arc. That's when we drop gravity. Any other time, restore it so
	-- falls and grounded movement feel normal.
	if hum.FloorMaterial == Enum.Material.Air and math.abs(hrp.AssemblyLinearVelocity.Y) < config.ApexGravityMinVelocity then
		workspace.Gravity = origGravity*config.ApexGravityMultiplier
	else
		workspace.Gravity = origGravity
	end
end

plr.CharacterAdded:Connect(function(newChr)
	chr = newChr
	hum = newChr:WaitForChild("Humanoid")
	hrp = newChr.PrimaryPart
end)

return function(enabled : boolean, newConfig : {})

	for i, v in (newConfig or {}) do
		config[i] = v
	end

	if enabled then
		table.insert(conns, game.RunService.Heartbeat:Connect(upd))
	else
		for _, conn in conns do
			conn:Disconnect()
		end
		conns = {}
	end

end