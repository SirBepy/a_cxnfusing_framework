local rs = game.ReplicatedStorage
local service = rs:WaitForChild("Services"):WaitForChild("DialogueService")

local mod = require(service:WaitForChild("DialogueHandler"))
local dialogueGrabber = require(service:WaitForChild('DialogueGrabber'))
local animMod = require(service:WaitForChild("Util"):WaitForChild("Animator"))

local actions = service:WaitForChild("Actions")

local main = script.Parent
local bg = main.BG:WaitForChild("Main")
local bgEndPos = UDim2.fromScale(-2.005,-9)

local openPos = main.Position
local closedPos = UDim2.fromScale(openPos.X.Scale, openPos.Y.Scale+0.5)

local vp = main.Character:WaitForChild("3D")
local vpOpenPos = vp.Position
local vpClosedPos = UDim2.fromScale(vpOpenPos.X.Scale, vpOpenPos.Y.Scale+1)

local uis = game:GetService("UserInputService")
local cs = game:GetService("CollectionService")
local ts = game:GetService("TweenService")

local promptTag = "StartDialogue"
local isOpen = false
local addedChr : Model
local buttonsConns = {}

local useLetter = true

local controller

local function setUpCharacter(npc : Model)
	main.Character:FindFirstChild("Name").Text = npc.Name
	if addedChr then
		animMod:ClearInfo(addedChr)
		addedChr:Destroy()
	end
	local chr = npc:Clone()
	chr.Parent = vp:WaitForChild("World")
	chr:PivotTo(CFrame.new(0,0,0))

	if not vp:FindFirstChildOfClass("Camera") then
		local cam = Instance.new("Camera")
		cam.CFrame = CFrame.new(Vector3.new(1.3,0,-4.5), Vector3.zero)
		cam.Parent = vp
		vp.CurrentCamera = cam
	end

	local idleAnim = chr:FindFirstChild("Poses") and chr.Poses:FindFirstChild("Idle")
	if idleAnim then
		animMod:SetUp(chr)
		animMod:LoadAnims(chr, chr.Poses)
		animMod:PlayAnim(chr, nil, idleAnim, 0)
	end
	addedChr = chr
end

local function open()
	if isOpen then return end
	isOpen = true
	main.Visible = true
	main.Position = closedPos
	vp.Position = vpClosedPos
	vp.ImageTransparency = 1
	ts:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut), {Position = openPos}):Play()
	task.wait(0.2)
	ts:Create(vp, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = vpOpenPos, ImageTransparency = 0}):Play()
end

local function close()
	if not isOpen then return end
	isOpen = false
	ts:Create(vp, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = vpClosedPos, ImageTransparency = 1}):Play()
	ts:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.In), {Position = closedPos}):Play()
	if controller and controller.Restart then
		controller:Restart()
		controller = nil
	end
end

local engine = mod.new({
	
	TextType = useLetter and "Letter" or "InLabel",
	ReplyTemplate = script.Response,
	
	TypewriterConfig = {
		TypeFrame = main:WaitForChild("Dialogue"), 
		TypeSound = script.Type,
		PitchVariation = {0.8, 1.5},
	},
	
}, main)

local function talk(data, npc)
	
	if useLetter then
		main.DialogueTextLabel.Visible = false
		main.Dialogue.Visible = true
	else
		main.Dialogue.Visible = false
		main.DialogueTextLabel.Visible = true
	end
	
	setUpCharacter(npc)
	open()

	controller = engine:StartConversation(data, npc)

	controller.StateChanged:Connect(function(state)
		if state == "WaitingToContinue" then
			main.NextButton.Visible = true
		elseif state == "Typing" or state == "WaitingForReply" then
			main.NextButton.Visible = false
		end
	end)

	controller.ReplyAdded:Connect(function(replyBtn)
		local ySize = 0.8
		replyBtn.MaxVisibleGraphemes = 0
		replyBtn.Size = UDim2.fromScale(0,0)
		replyBtn.UIStroke.Transparency = 1

		ts:Create(replyBtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {Transparency = 0}):Play()
		ts:Create(replyBtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {MaxVisibleGraphemes = #replyBtn.Text, Size = UDim2.fromScale(0,ySize)}):Play()

		buttonsConns[replyBtn] = {
			replyBtn.MouseEnter:Connect(function()
				ts:Create(replyBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(0,1)}):Play()
			end),
			replyBtn.MouseLeave:Connect(function()
				ts:Create(replyBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.fromScale(0,ySize)}):Play()
			end),
		}
	end)

	controller.ReplyRemoved:Connect(function(replyBtn)
		if buttonsConns[replyBtn] then
			for _, conn in pairs(buttonsConns[replyBtn]) do conn:Disconnect() end
			buttonsConns[replyBtn] = nil
		end
		ts:Create(replyBtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {MaxVisibleGraphemes = 0, TextTransparency = 0.5, Size = UDim2.fromScale(0,0)}):Play()
		ts:Create(replyBtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Transparency = 1}):Play()
	end)

	controller.CommandRun:Connect(function(command, arg)
		if command == "pose" then
			if not addedChr or not arg then return end
			animMod:StopAllAnims(addedChr)
			animMod:PlayAnim(addedChr, arg, nil, 0)
		end
		for _, action in pairs(actions:GetChildren()) do
			if action.Name == command and action:IsA("ModuleScript") then
				local req = require(action)
				req(action)
			end
		end
	end)
	
	controller.LetterTyped:Connect(function(data : {Instance : TextLabel})
		if not useLetter then return end
		data.Instance.TextTransparency = 1
		ts:Create(data.Instance, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	end)
	
end

main.NextButton.MouseButton1Click:Connect(function()
	if engine.Controller then engine.Controller:Continue() end
end)

uis.InputBegan:Connect(function(inp, proc)
	if proc then return end

	if inp.KeyCode == Enum.KeyCode.Return or inp.UserInputType == Enum.UserInputType.MouseButton1 then
		local ctrl = engine.Controller
		if ctrl and ctrl.Continue and ctrl.Skip then
			ctrl:Continue()
			ctrl:Skip()
		end
	end
end)

local function handlePrompt(prompt)
	prompt.Triggered:Connect(function(plr)
		if plr ~= game.Players.LocalPlayer then return end
		local convo, npc = dialogueGrabber:Grab(prompt)
		if convo and not isOpen then talk(convo, npc) end
	end)
end

for _, p in pairs(cs:GetTagged(promptTag)) do handlePrompt(p) end
cs:GetInstanceAddedSignal(promptTag):Connect(handlePrompt)

engine.OpenUI:Connect(open)
engine.CloseUI:Connect(close)

ts:Create(bg, TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false), {Position = bgEndPos}):Play()
main.Position = closedPos