--[[
	Conversations/Greeting

	Purpose:
		A sample conversation graph. Each entry is a node with a unique
		Label, the Text to type, a Type ("Dialogue" or "Reply"), and
		Connections - the labels of nodes this one can lead to.

	When to use:
		DialogueGrabber returns this module when a prompt's ID resolves
		to "Greeting". DialogueHandler then walks the graph:
		  - Dialogue nodes type out and either auto-advance or wait for
		    Continue.
		  - Reply nodes spawn a button for the player; picking one jumps
		    to that reply's first Connection.

	Example shape:
		{
			{ Label = "Start", Start = true, Type = "Dialogue",
			  Text = "Hi!", Connections = { "YesReply", "NoReply" } },
			{ Label = "YesReply", Type = "Reply",
			  Text = "Hello!", Connections = { "Bye" } },
			...
		}

	Gotchas:
		- Exactly one node should have `Start = true`; otherwise the
		  handler falls back to the first entry.
		- Position is only a hint for editor tools (if any); runtime
		  ignores it.
		- Text supports `<plrName>`, `<npcName>`, effect tags (<wave>,
		  <rainbow>, <b>, etc.), and `$command:arg$` tokens. See
		  Conversations/Info.luau for the full grammar reference.
--]]

return
	{
		{
			Label = "FollowUp",
			Text = [[Nice to meet you <wave><rainbow><b><plrName></b>!</rainbow></wave>
I'll see you around.]],
			Position = UDim2.fromOffset(761, -232),
			Connections = {  },
			Type = "Dialogue",
		},
		{
			Label = "Decline",
			Text = [[Umm... bye!]],
			Position = UDim2.fromOffset(390, 44),
			Connections = {  },
			Type = "Reply",
		},
		{
			Label = "Name",
			Text = [[I'm <b><plrName></b>!]],
			Position = UDim2.fromOffset(399, -86),
			Connections = { "FollowUp" },
			Type = "Reply",
		},
		{
			Label = "OnStart",
			Start = true,
			Text = [[Hey$pose:Greet$ I'm <b><npcName></b>!
$pose:Idle$What's your name?]],
			Position = UDim2.fromOffset(0, 0),
			Connections = { "Name", "Decline" },
			Type = "Dialogue",
		},
	}
