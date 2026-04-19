--[[
	DialogueHandler

	Purpose:
		The core runtime for a conversation. Takes a parsed conversation
		(an array of nodes with Label/Text/Connections/Type) plus a UI
		container and plays it out node-by-node: types text, fires a few
		signals, and branches on Reply vs Dialogue connections.

	When to use:
		Spin up ONE instance per UI (typically one per player's dialogue
		GUI). Call :StartConversation(data, npc) whenever you want a
		conversation to begin. The returned Controller is your remote
		for that specific run: Skip/Continue/Restart/Destroy + signals.

	Example:
		local handler = DialogueMod.new({
			TextType = "Letter",
			ReplyTemplate = myReplyButton,
			TypewriterConfig = {
				TypeFrame = dialogueFrame,
				LetterTemplate = letterTemplate,
				-- ...
			},
		}, myDialogueUI)

		handler.OpenUI:Connect(function() myDialogueUI.Visible = true end)
		handler.CloseUI:Connect(function() myDialogueUI.Visible = false end)

		local convo, npc = grabber:Grab(prompt)
		local controller = handler:StartConversation(convo, npc)

		controller.CommandRun:Connect(function(cmd, arg)
			-- e.g. handle $pose:Greet$ or your own custom commands.
		end)

		UserInputService.InputBegan:Connect(function(i, p)
			if p then return end
			if i.KeyCode == Enum.KeyCode.E then
				-- First press skips the typewriter, second advances.
				controller:Skip()
				controller:Continue()
			end
		end)

	Gotchas:
		- "InLabel" mode uses MaxVisibleGraphemes on a single label (simple,
		  cheap, no effects). "Letter" mode spawns one TextLabel per
		  character so per-letter effects like wave/rainbow work.
		- Controller:Continue() is debounced ~0.2s after a Skip so the
		  same keypress doesn't both skip and advance.
		- The reply wait uses a busy loop (`repeat task.wait() until
		  selected`). Works fine, but don't expect a tight frame budget
		  while idling on a choice.
		- You're responsible for firing OpenUI yourself if you want it;
		  this module only fires CloseUI at the end of a convo.
--]]

local DialogueMod = {}
DialogueMod.__index = DialogueMod

local util = script.Parent:WaitForChild("Util")
local Typewriter = require(util:WaitForChild("Typewriter"))
local signal = require(util:WaitForChild("Signal"))
local replace = require(script:WaitForChild("Replace"))

type sig = typeof(signal())

function DialogueMod.new(Config : {
	
	TextType : "InLabel" | "Letter",
	
	ReplyTemplate : TextButton,
	TypewriterConfig : typeof(Typewriter.DefaultConfig),	
	
	}, UI)
	local self = setmetatable({}, DialogueMod)
	self.Config = Config
	self.UI = UI
	self.OpenUI = signal()
	self.CloseUI = signal()

	self.Controller = {
		StateChanged = signal(),
		ReplyAdded = signal(),
		ReplyRemoved = signal(),
		CommandRun = signal(),
		LetterTyped = signal(),
	}

	return self :: typeof(self)
end

function DialogueMod:StartConversation(data, npc)
	-- Build a Label -> node map once so Connections can be followed in O(1).
	local lookup = {}
	for _, node in ipairs(data) do lookup[node.Label] = node end

	-- Prefer the node flagged Start=true; fall back to the first node so
	-- conversations authored without an explicit entry point still run.
	local current = nil
	for _, node in ipairs(data) do if node.Start then current = node break end end
	current = current or data[1]

	local Controller = self.Controller :: {
		
		StateChanged : sig,
		ReplyAdded : sig,
		ReplyRemoved : sig,
		CommandRun : sig,
		LetterTyped : sig,
		
		Skip : ()->(),
		Continue : ()->(),
		Destroy : ()->(),
		Restart : ()->(),
		
	}
	local continue = false
	local activeTW = nil
	local skipTimestamp = 0

	Typewriter:SetConfig(self.Config.TypewriterConfig)
	
	function Controller:Continue()
		-- Debounce: if Skip just happened, ignore the immediate follow-up
		-- Continue so a single keypress doesn't skip AND advance at once.
		if os.clock() - skipTimestamp > 0.2 then
			continue = true
		end
	end

	function Controller:Skip()
		if activeTW then 
			activeTW:Skip() 
			skipTimestamp = os.clock()
		end 
	end
	
	function Controller:Destroy()
		Controller:Restart()
		for i, v in Controller do
			Controller[i] = nil
		end
		Controller = nil
	end
	
	function Controller:Restart()
		if activeTW and activeTW.Destroy then
			activeTW:Destroy()
			activeTW = nil
		end		
	end

	task.spawn(function()
		while current do
			continue = false
			local text, commands = replace(current.Text, npc, game.Players.LocalPlayer)
			local triggeredCommands = {} 

			Controller.StateChanged:Fire("Typing")
			
			local currentTW
			
			if self.Config.TextType == "InLabel" then
				currentTW = Typewriter:TypeInLabel(self.UI:WaitForChild("DialogueTextLabel"), text)
			else
				currentTW = Typewriter:Type(text)
			end
			activeTW = currentTW
			
			-- Index 0 = commands that appeared BEFORE the first visible
			-- character (e.g. "$pose:Greet$Hi!"). Fire them up-front so
			-- they land before the first letter types.
			if commands and commands[0] then
				triggeredCommands[0] = true
				local cmdData = commands[0]
				if cmdData.command ~= "wait" then
					Controller.CommandRun:Fire(cmdData.command, cmdData.arguments)
				else
					currentTW:Wait(cmdData.arguments)
				end
			end
			local cmdConn = currentTW.OnLetterTyped:Connect(function(data : {Letter : string, Index : number})
				local num = data.Index
				if commands and commands[num] then
					triggeredCommands[num] = true
					local cmd, arg = commands[num].command, commands[num].arguments
					if cmd == "wait" then 
						currentTW:Wait(arg) 
					else 
						Controller.CommandRun:Fire(cmd, arg)
					end
				end
				Controller.LetterTyped:Fire(data)
			end)

			currentTW.Completed:Wait()

			-- Safety net: if a command was anchored to an index beyond the
			-- last typed letter (trailing `$cmd$` after all text), it would
			-- never fire through OnLetterTyped. Flush leftovers here.
			if commands then
				for num, cmdData in pairs(commands) do
					if not triggeredCommands[num] then
						if cmdData.command ~= "wait" then
							Controller.CommandRun:Fire(cmdData.command, cmdData.arguments)
						end
						triggeredCommands[num] = true
					end
				end
			end

			cmdConn:Disconnect()

			local replies = {}
			local autoNext = nil

			-- Split this node's outgoing connections into player-choice
			-- replies vs. an auto-advance next dialogue node. If both kinds
			-- exist, replies win (autoNext is only used when there are none).
			for _, connLabel in ipairs(current.Connections) do
				local target = lookup[connLabel]
				if target then
					if target.Type == "Reply" then table.insert(replies, target)
					elseif target.Type == "Dialogue" then autoNext = target end
				end
			end
			
			continue = false
			if #replies > 0 then
				Controller.StateChanged:Fire("WaitingForReply")
				local container = self.UI:WaitForChild("RepliesContainer")
				local selected = nil

				for _, rData in ipairs(replies) do
					local btn = self.Config.ReplyTemplate:Clone()
					btn.Text = replace(rData.Text, npc, game.Players.LocalPlayer)
					btn.Parent = container
					btn.Visible = true
					btn.MouseButton1Click:Connect(function() selected = rData end)
					Controller.ReplyAdded:Fire(btn)
				end

				-- Busy-wait for a click. Fine in practice since it's a
				-- human-scale decision, but it does poll every frame.
				repeat task.wait() until selected

				for _, child in pairs(container:GetChildren()) do
					if child:IsA("GuiButton") then
						Controller.ReplyRemoved:Fire(child)
						task.delay(0.3, function() child:Destroy() end)
					end
				end

				current = lookup[selected.Connections[1]]
			elseif autoNext then
				Controller.StateChanged:Fire("WaitingToContinue")
				repeat task.wait() until continue
				current = autoNext
			else
				Controller.StateChanged:Fire("WaitingToContinue")
				repeat task.wait() until continue
				current = nil
			end
		end

		self.CloseUI:Fire()
		Controller.StateChanged:Fire("Complete")
	end)

	return Controller
end

return DialogueMod