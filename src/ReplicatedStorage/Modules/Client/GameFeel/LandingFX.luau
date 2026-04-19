local lastGrounded
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
	
	if grounded and not fxShown and (lastGrounded.Y-hrp.Position.Y) > config.LandingFXMinHeight then
		fxShown = true
		local pos = hrp.Position+Vector3.new(0,-3,0)
		local hitRay = workspace:Raycast(hrp.Position, -Vector3.yAxis*7, rayParams)
		if hitRay then pos = hitRay.Position+Vector3.yAxis*0.1 end
		VFX.newVFX({VFXName = "Landing", Position = pos})
	end
	
	if grounded then
		lastGrounded = hrp.Position
	else
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