local Observer = require(game.ReplicatedStorage.Framework).Utilities.Observer
local data = {
	Value = "Awesome",
	Other = 2,
}

local data = Observer.new(data, function()
	print(data.Other)
end)

task.wait(3)

data.Value = "lol"