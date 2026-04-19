local GameFeel = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("GameFeel"))
local Framework = require(game:GetService("ReplicatedStorage"):WaitForChild("Framework"))

Framework:WaitUntilLoaded()

GameFeel:SetAll(true)