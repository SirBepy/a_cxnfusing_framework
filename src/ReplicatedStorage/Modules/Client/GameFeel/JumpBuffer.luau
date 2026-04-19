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

local function bufferCheck()
	if not isAlive() then return end

	if os.clock() - lastJumpRequest <= config.JumpBufferTime then
		if hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			lastJumpRequest = 0 
		end
	end
end

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