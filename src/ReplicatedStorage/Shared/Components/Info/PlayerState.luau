local plr = game.Players.LocalPlayer
local signal = require(script.Parent.Parent.Util).Signal

if not game:GetService("RunService"):IsClient() then return true :: data end

type signal = typeof(signal())
type data = {

	Character : Model,
	CharacterAdded : signal,

	HRP : BasePart,
	Humanoid : Humanoid,

	Connections : {[string] : RBXScriptConnection},

}

local data = {

	Character = plr.Character,
	CharacterAdded = signal(),

	Connections = {},

}::data

data.Character = plr.Character or plr.CharacterAdded:Wait()
data.HRP = data.Character:WaitForChild("HumanoidRootPart")
data.Humanoid = data.Character:WaitForChild("Humanoid")

plr.CharacterAdded:Connect(function(chr)

	data.Character = chr
	data.HRP = chr:WaitForChild("HumanoidRootPart")
	data.Humanoid = chr:WaitForChild("Humanoid")

	data.CharacterAdded:Fire(chr)

end)

return data