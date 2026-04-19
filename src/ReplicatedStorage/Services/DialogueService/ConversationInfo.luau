--[[
	ConversationInfo

	Purpose:
		The routing table DialogueGrabber uses to pick a conversation.
		Each key is a prompt ID (set via the ProximityPrompt's "ID"
		attribute). Value is a Default conversation name + optional
		Conditioned variants.

	When to use:
		Add an entry here every time you wire up a new NPC/prompt.
		The Default name must match a ModuleScript in Conversations/.

	Example:
		Shopkeeper = {
			Default = "ShopGreeting",
			Conditioned = {
				-- If BOTH "IsNight" and "HasQuest" pass, use NightQuest instead.
				NightQuest = { "IsNight", "HasQuest" },
			},
		},

	Gotchas:
		- Conditioned keys are the CONVERSATION names, values are the
		  list of condition modules (in Conditions/) that must all return
		  true. The order you list them in is the AND-check order.
		- Iteration order of Conditioned entries is not guaranteed; don't
		  rely on priority when two variants could pass at once.
--]]

type t = {
	[string] : {
		Default : string,
		Conditioned : {
			[string] : {string},
		}
	}
}

local info : t = {
	
	DefaultRig = {
		Default = "Greeting",
	},
	
}

return info