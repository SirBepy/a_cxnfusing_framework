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
		lastGrounded = os.clock()
		if os.clock()-lastJumped<0.05 then return end
		hasJumped = false
	end
end

local function keyCheck(inp, proc)
	if not isAlive() then return end
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