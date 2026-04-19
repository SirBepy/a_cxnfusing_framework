--[[
	LandingFX

	Purpose:
		Spawns a landing VFX (dust puff, impact, whatever "Landing" is
		wired up to in the VFX service) when the player lands from a
		jump/fall tall enough to be worth sparkling about.

	When to use:
		Enable via GameFeel for that bit of weight and feedback when
		players land. Tune LandingFXMinHeight (studs) so short hops
		don't constantly puff dust.

	Example:
		GameFeel:Set("LandingFX", true)

	Gotchas:
		- Uses the character's last grounded position Y vs current Y to
		  measure fall distance, so jumping UP then landing back at the
		  same height won't trigger VFX (that's intentional).
		- Raycasts down from the HRP to find the actual ground so the
		  VFX sits on the surface, not floating inside the character.
]]

-- lastGrounded is a Vector3 (not a timestamp like CoyoteTime uses).
-- We track position so we can measure fall height on landing.
local lastGrounded
-- fxShown starts true so the spawn-frame doesn't count as "just landed"
-- and play VFX for a fall that never happened.
local fxShown = true

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local hum : Humanoid = chr:WaitForChild("Humanoid")
local hrp : BasePart = chr.PrimaryPart
lastGrounded = hrp.Position

local Shared = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"))
local VFX = Shared.Services.VFX

local config = {
	LandingFXMinHeight = 10,
}

local conns = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {chr}

local function isAlive()
	if not hum or hum.Health <= 0 then return end
	return true
end

local function airCheck()
	if not isAlive() then return end

	local grounded = hum.FloorMaterial ~= Enum.Material.Air

	-- Landing frame: just touched down, haven't already shown the FX
	-- this fall, and fell from high enough to matter.
	if grounded and not fxShown and (lastGrounded.Y-hrp.Position.Y) > config.LandingFXMinHeight then
		fxShown = true
		-- Fallback position is a rough guess below the HRP in case the
		-- ray misses (e.g. landed on a thin part at a weird angle).
		local pos = hrp.Position+Vector3.new(0,-3,0)
		-- Raycast down to pin the VFX to the actual ground surface.
		-- +0.1 studs so it doesn't z-fight with the floor.
		local hitRay = workspace:Raycast(hrp.Position, -Vector3.yAxis*7, rayParams)
		if hitRay then pos = hitRay.Position+Vector3.yAxis*0.1 end
		VFX.newVFX({VFXName = "Landing", Position = pos})
	end

	if grounded then
		-- Keep lastGrounded fresh while on the floor so the next fall's
		-- height is measured from where we actually left the ground.
		lastGrounded = hrp.Position
	else
		-- As soon as we leave the ground, arm the FX for the next landing.
		fxShown = false
	end

end

plr.CharacterAdded:Connect(function(newChr)
	
	chr = newChr
	hum = newChr:WaitForChild("Humanoid")
	hrp = newChr.PrimaryPart
	
	rayParams.FilterDescendantsInstances = {newChr}
	
end)

return function(enabled : boolean, newConfig : {})

	for i, v in (newConfig or {}) do
		config[i] = v
	end

	if enabled then
		table.insert(conns, game.RunService.Heartbeat:Connect(airCheck))
	else
		for _, conn in conns do
			conn:Disconnect()
		end
		conns = {}
	end

end