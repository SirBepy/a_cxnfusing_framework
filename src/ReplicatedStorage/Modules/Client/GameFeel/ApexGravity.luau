local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local hum : Humanoid = chr:WaitForChild("Humanoid")
local hrp : BasePart = chr.PrimaryPart

local uis = game:GetService("UserInputService")

local config = {
	ApexGravityMultiplier = 0.5,
	ApexGravityMinVelocity = 12
}

local origGravity = workspace.Gravity

local conns = {}

local function isAlive()
	if not hum or hum.Health <= 0 or not hrp then return end
	return true
end

local function upd()
	if not isAlive() then return end
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