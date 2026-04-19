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
