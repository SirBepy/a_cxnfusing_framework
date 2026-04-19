local rs = game:GetService("ReplicatedStorage")
local Framework = require(rs:WaitForChild("Framework"))
Framework:WaitUntilLoaded()

local assets = rs:WaitForChild("Assets"):WaitForChild("LODTesting")

local pos = CFrame.new(30,5,0)

Framework.Utilities.LODManager:Register(pos, {
	{Model = assets:WaitForChild("High"), Distance = 20},
	{Model = assets:WaitForChild("Mid"), Distance = 40},
	{Model = assets:WaitForChild("Low"), Distance = 80},
})