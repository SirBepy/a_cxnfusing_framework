--[[
	JumpBuffer

	Purpose:
		"Jump buffering" means remembering that the player pressed jump
		slightly before landing, and firing the jump as soon as they
		touch ground. Without it, mashing jump right before you land
		just eats the input and feels unresponsive.

	When to use:
		Enable via GameFeel for any game with platforming. Tune
		JumpBufferTime (seconds) to control how early a press still
		counts. 0.1 to 0.2 is standard.

	Example:
		GameFeel:Set("JumpBuffer", true)

	Gotchas:
		- Only records a press if the player is currently airborne, so
		  normal grounded jumps fall through to Roblox's own handler.
		- Fires via Humanoid:ChangeState(Jumping), which bypasses the
		  Humanoid's JumpCooldown.
]]

-- When the player last pressed jump while airborne. 0 = nothing buffered.
local lastJumpRequest = 0

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local hum : Humanoid = chr:WaitForChild("Humanoid")

local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local config = {
	JumpBufferTime = 0.15,
}

local conns = {}

local function isAlive()
	if not hum or hum.Health <= 0 then return end
	return true
end

-- Every frame: if there's a buffered press that hasn't expired, and
-- the player just touched ground, fire the jump and clear the buffer.
local function bufferCheck()
	if not isAlive() then return end

	if os.clock() - lastJumpRequest <= config.JumpBufferTime then
		if hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			lastJumpRequest = 0
		end
	end
end

-- Only buffer presses made while airborne. Grounded presses are just
-- normal jumps, no need to interfere.
local function onJumpRequest()
	if not isAlive() then return end

	if hum.FloorMaterial == Enum.Material.Air then
		lastJumpRequest = os.clock()
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
		table.insert(conns, runService.Heartbeat:Connect(bufferCheck))
		table.insert(conns, uis.JumpRequest:Connect(onJumpRequest))
	else
		for _, conn in conns do
			conn:Disconnect()
		end
		conns = {}
		lastJumpRequest = 0
	end

end