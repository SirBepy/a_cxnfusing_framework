--[[
	CoyoteTime

	Purpose:
		"Coyote time" is the tiny grace window after you walk off a
		ledge during which you can still jump, like the coyote in old
		cartoons hovering in mid-air for a beat before gravity kicks
		in. Makes platforming feel way less punishing.

	When to use:
		Enable via GameFeel for any platformer-ish game where players
		are expected to time jumps off ledges. Tune CoyoteTime (seconds)
		to taste. 0.1 to 0.2 is the usual sweet spot.

	Example:
		GameFeel:Set("CoyoteTime", true)

	Gotchas:
		- Fires a manual Humanoid:ChangeState(Jumping) when the grace
		  window is active, so it ignores the normal jump-cooldown.
		- `hasJumped` guards against double-jumping within one airborne
		  stretch. It resets only after the player touches floor again.
]]

-- Timestamps for the last time we were on the floor and the last time
-- we fired a jump. Using os.clock so we don't care about server time.
local lastGrounded = os.clock()
local lastJumped = os.clock()
local hasJumped = false

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local hum : Humanoid = chr:WaitForChild("Humanoid")

local uis = game:GetService("UserInputService")

local config = {
	CoyoteTime = 0.15,
}

local conns = {}

local function isAlive()
	if not hum or hum.Health <= 0 then return end
	return true
end

local function airCheck()
	if not isAlive() then return end
	if hum.FloorMaterial ~= Enum.Material.Air then
		-- Refresh "last grounded" every frame we're on the floor so the
		-- coyote window is measured from when we actually leave it.
		lastGrounded = os.clock()
		-- Ignore floor contact for the first few ms after a jump. Roblox
		-- sometimes reports FloorMaterial briefly while the character
		-- is still clipping the ground, which would instantly reset
		-- hasJumped and let the player double-jump.
		if os.clock()-lastJumped<0.05 then return end
		hasJumped = false
	end
end

local function keyCheck(inp, proc)
	if not isAlive() then return end
	-- Only intervene when Roblox's own jump logic wouldn't fire: we're
	-- in the air, still inside the coyote window, and haven't already
	-- spent this airborne jump.
	if
		hum.FloorMaterial == Enum.Material.Air and
		os.clock()-lastGrounded <= config.CoyoteTime and
		not hasJumped
	then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		lastJumped = os.clock()
		hasJumped = true
	end
end

-- Catches jumps that came from somewhere other than our keyCheck
-- (normal grounded jump, scripted jump, etc.) so hasJumped stays
-- accurate no matter who triggered the state change.
local function stateCheck(old : Enum.HumanoidStateType, new : Enum.HumanoidStateType)
	if new == Enum.HumanoidStateType.Jumping then
		lastJumped = os.clock()
		hasJumped = true
	end
end

plr.CharacterAdded:Connect(function(newChr)
	chr = newChr
	hum = newChr:WaitForChild("Humanoid")
end)

return function(enabled : boolean, newConfig : {})

	for i, v in (newConfig or {}) do
		config[i] = v
	end

	if enabled then
		table.insert(conns, game.RunService.Heartbeat:Connect(airCheck))
		table.insert(conns, hum.StateChanged:Connect(stateCheck))
		table.insert(conns, uis.JumpRequest:Connect(keyCheck))
	else
		for _, conn in conns do
			conn:Disconnect()
		end
		conns = {}
	end

end