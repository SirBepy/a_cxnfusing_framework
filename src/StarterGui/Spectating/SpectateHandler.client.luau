local rs = game:GetService("ReplicatedStorage")
local Framework = require(rs:WaitForChild("Framework"))
Framework:WaitUntilLoaded()

local plrs = game.Players:GetPlayers()
local ourPlr = game.Players.LocalPlayer

local ui = script.Parent
local mainFrame = ui:WaitForChild("Main")
local toggleButton = ui:WaitForChild("SpectateButton")

local spectateService = Framework.Utilities.SpectateService

local on = false
local curIndex = 1

local function upd()
	if not on then spectateService:StopWatching() return end
	local cur = plrs[curIndex] or plrs[1]
	if not cur then return end
	spectateService:Watch(cur)
end

local function inc(amount : number)
	amount = amount or 1
	curIndex+=amount
	if curIndex <= 0 then
		curIndex = #plrs
	elseif curIndex > #plrs then
		curIndex = 1
	end
	upd()
end

toggleButton.MouseButton1Click:Connect(function()
	on = not on
	if #plrs == 0 and on then
		on = false
	end
	mainFrame.Visible = on
	upd()
end)

mainFrame.Right.MouseButton1Click:Connect(function()
	inc(1)
end)
mainFrame.Left.MouseButton1Click:Connect(function()
	inc(-1)
end)

game.Players.PlayerAdded:Connect(function(newPlr : Player)
	if newPlr == ourPlr then return end
	table.insert(plrs, newPlr)
end)
game.Players.PlayerRemoving:Connect(function(plr : Players)
	if plr == ourPlr then return end
	local found = table.find(plrs, plr)
	if not found then return end
	table.remove(plrs, found)
end)

for _, plr in plrs do
	if plr == ourPlr then 
		local found = table.find(plrs, plr)
		if not found then continue end
		table.remove(plrs, found)
	end
end

spectateService:Init()