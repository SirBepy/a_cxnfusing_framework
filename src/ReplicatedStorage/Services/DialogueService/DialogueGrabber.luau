--[[
	DialogueGrabber

	Purpose:
		Given a ProximityPrompt on an NPC, figure out which conversation
		module to hand back. Reads the prompt's "ID" attribute, looks it up
		in ConversationInfo, then picks between a Default conversation and
		any Conditioned variants (based on runtime checks from Conditions/).

	When to use:
		Call :Grab(prompt) the moment the player triggers a dialogue prompt.
		It returns the required conversation table + the NPC model so
		DialogueHandler can start playing it.

	Example:
		local grabber = require(path.to.DialogueGrabber)
		prompt.Triggered:Connect(function()
			local convo, npc = grabber:Grab(prompt)
			if convo then dialogue:StartConversation(convo, npc) end
		end)

	Gotchas:
		- Prompts MUST have an "ID" attribute that matches a key in
		  ConversationInfo; otherwise :Grab silently returns nil.
		- Conditioned entries are iterated in pairs() order, so if two
		  conditions can both pass, the "winner" isn't deterministic.
		- Conditions must live under Services/DialogueService/Conditions
		  and return a function(ctx) -> boolean.
--]]

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
		-- Walk each candidate conversation and AND its conditions together.
		-- First option whose conditions ALL pass wins and overrides Default.
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