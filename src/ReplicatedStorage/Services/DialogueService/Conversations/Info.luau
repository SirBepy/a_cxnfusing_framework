--[[
	Conversations/Info

	Purpose:
		This file is NOT a real conversation. It's a GRAMMAR REFERENCE
		disguised as one, a cheat sheet for everything you can stuff
		into a dialogue node's Text field. Keep it here so authors can
		glance at it without leaving the Conversations folder.

	When to use:
		Open it whenever you're writing a new conversation and can't
		remember the exact placeholder or command syntax.

	Gotchas:
		- Do NOT add this module to ConversationInfo.luau; it returns
		  nothing and would crash DialogueHandler if routed to.
		- Adding new effect tags or commands here is just documentation,
		  you still have to implement them in Typewriter/Effects/ or
		  your CommandRun listener.

	----------------------------------------------------------------
	Reference (safe to edit when you add new variables / commands):

	-- Variables (substituted by DialogueHandler/Replace.luau)

	<plrName> = the player's display name
	<npcName> = the npc's model name

	-- Commands (fired through Controller.CommandRun, except `wait`)

	$pose:PoseName$ = changes the npc's pose (handled by your listener)
	$wait:Time$     = halts the typewriter for Time seconds

	-- Effect tags (handled by Typewriter's per-letter effects)

	<b>...</b>         = bold
	<i>...</i>         = italic
	<wave>...</wave>   = vertical sine-wave bob
	<rainbow>...       = HSV colour cycle
	<wobble>...        = Lissajous jitter
	<pulse>...         = scale pulse
	<ghost>...         = fading transparency
	<glitch>...        = chromatic aberration flicker
--]]