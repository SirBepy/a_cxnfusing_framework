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
	local lookup = {}
	for _, node in ipairs(data) do lookup[node.Label] = node end

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