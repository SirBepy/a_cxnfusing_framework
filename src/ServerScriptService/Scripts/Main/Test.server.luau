local Framework = require(game:GetService("ReplicatedStorage").Framework)

Framework.Functions.FastTween(
	workspace.SpawnLocation,
	{2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut, -1, true},
	{Size = Vector3.new(5,30,5), Position = Vector3.new(0,10,0)}
)

task.wait(3)

local function boom()
	for i = 1, 2 do
		Framework.Services.VFX.newVFX({Position = Vector3.new(math.random(-20,20), 10, math.random(-20,20)), VFXName = "Explosion"})
		if i % 9 == 0 then task.wait() end
	end
end

boom()

task.wait(5)

boom()