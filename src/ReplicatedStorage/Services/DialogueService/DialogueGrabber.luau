local grabber = {}

local rs = game.ReplicatedStorage
local serv = script.Parent

local convos = serv:WaitForChild("Conversations")
local convoInfo = require(serv:WaitForChild("ConversationInfo"))

local loadedConditions = {}

local plr = game.Players.LocalPlayer

for _, cond in pairs(serv:WaitForChild("Conditions"):GetChildren()) do
	loadedConditions[cond.Name] = require(cond)
end

function grabber:Grab(prompt : ProximityPrompt) : ({}, Model)

	local id = prompt:GetAttribute("ID")
	local info = convoInfo[id]

	if not info then return end

	local chosen = info.Default

	if info.Conditioned then
		for option, conditions in pairs(info.Conditioned) do
			local suc = true
			for _, condition in conditions do
				if loadedConditions[condition] then
					if not loadedConditions[condition]({player = plr, npc = prompt:FindFirstAncestorWhichIsA("Model")}) then
						suc = false
						break
					end
				end
			end
			if suc then
				chosen = option
				break
			end
		end
	end

	local convo = convos:FindFirstChild(chosen) and require(convos[chosen])

	return convo, prompt:FindFirstAncestorWhichIsA("Model")

end

return grabber