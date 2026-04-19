local Framework = require(game:GetService("ReplicatedStorage").Framework)
local spring = Framework.Utilities.Spring.new(script.Parent.Position, 0.1, 20)
local dt = 0
local last = os.clock()
while task.wait() do
	dt += os.clock()-last
	last = os.clock()
	script.Parent.Position = spring.Position
	if dt < 4 then continue end
	dt = 0
	spring:Impulse(Vector3.new(0,0,100))
end