local Typewriter = {}

---<>--- Variables ---<>---

local DefaultConfig = {

	LetterTemplate = script:WaitForChild("Assets"):WaitForChild("LetterTemp"),

	TypeSound = script:WaitForChild("Assets"):WaitForChild("TypeSound"),
	SoundStacks = true,
	PitchVariation = {0.95, 1.05},
	PlaySoundOnSpace = false,

	DefaultTypeSpeed = 0.03,
	PunctuationPauseLength = 0.5,
	CommaPauseLength = 0.2,

}
local Config = DefaultConfig :: Config

local effectFolder = script:WaitForChild("Effects")
local loadedEffects = {} :: {[string] : (TextLabel)->(RBXScriptConnection)}

local util = script:WaitForChild("Util")
local signal = require(util:WaitForChild("Signal"))
local parse = require(util:WaitForChild("Parse"))
local layoutMaker = require(util:WaitForChild("Layout"))

local commaList = {",", ";"}
local puncList = {".", "?", "!"}

type sig = typeof(signal())
type Main = typeof(Typewriter)

type Config = {
	TypeFrame : CanvasGroup | Frame,
	LetterTemplate : TextLabel,

	TypeSound : Sound,
	SoundStacks : boolean,
	PitchVariation : {number},
	PlaySoundOnSpace : boolean,

	DefaultTypeSpeed : number,
	PunctuationPauseLength : number,
	CommaPauseLength : number,
}

Typewriter.DefaultConfig = {} :: Config

---<>--- Helpers ---<>---

local function playTypeSound()

	local sound = Config.TypeSound
	if not sound then return end

	local playback = sound
	if Config.SoundStacks then
		playback = sound:Clone()
		playback.Parent = sound.Parent
		playback.Stopped:Connect(function() playback:Destroy() end)
	end

	local pitchEffect = playback:FindFirstChild("PitchShiftSoundEffect") or Instance.new("PitchShiftSoundEffect", playback)
	pitchEffect.Octave = math.random(Config.PitchVariation[1]*10, Config.PitchVariation[2]*10)/10
	playback:Play()

end

---<>--- Main Functions ---<>---

function Typewriter:SetConfig(NewConfig : {

	TypeFrame : CanvasGroup | Frame,
	LetterTemplate : TextLabel,

	TypeSound : Sound,
	SoundStacks : boolean,
	PitchVariation : {number},
	PlaySoundOnSpace : boolean,

	DefaultTypeSpeed : number,
	PunctuationPauseLength : number,
	CommaPauseLength : number,

	})

	NewConfig = NewConfig or DefaultConfig
	for index, val in NewConfig do
		Config[index] = val
	end

end

function Typewriter:Type(text : string) : {

	OnLetterTyped : sig,
	Completed : sig,

	Skip : ()->(),
	Cancel : ()->(),

	}
	if not Config.TypeFrame then warn("No type frame.") return end

	local Controller = {

		OnLetterTyped = signal(),-- gives {Letter : string, Index : number, Effects : {string}}
		Completed = signal(),

		_activeConnections = {},

	}

	local skipped = false
	local cancelled = false
	local waiting = false

	function Controller:Skip()
		skipped = true
	end

	function Controller:Destroy()

		for _, prevChr in Config.TypeFrame:GetChildren() do
			if prevChr:IsA("TextLabel") then
				prevChr:Destroy()
			end
		end

		for _, conn in Controller._activeConnections do
			conn:Disconnect()
		end
		for i, v in Controller do
			Controller[i] = nil
		end
		Controller = nil

	end

	function Controller:Cancel()

		cancelled = true
		Controller:Destroy()

	end
	
	function Controller:Wait(length : number)
		
		waiting = true
		task.delay(length, function()
			waiting = false
		end)
		
	end

	local raw = text or ""
	local characterData, stripped = parse(raw)

	local Layout = layoutMaker.new(
		Config.LetterTemplate.Font, 
		Config.TypeFrame.AbsoluteSize.X, 
		Config.LetterTemplate.TextSize
	)

	task.spawn(function()
		
		for _, prevChr in Config.TypeFrame:GetChildren() do
			if prevChr:IsA("TextLabel") then
				prevChr:Destroy()
			end
		end
		
		for i, data in characterData do
			if waiting then repeat task.wait() until not waiting or cancelled end
			if cancelled then return end

			local pos = Layout:GetNextPosition(data.Letter, stripped, data.Index, data.Effects)

			if not pos then continue end

			local newLabel = Config.LetterTemplate:Clone()
			newLabel.Position = pos
			newLabel.Text = data.Letter
			newLabel.Parent = Config.TypeFrame

			for _, effectName in data.Effects do
				local effectFunc = loadedEffects[effectName]
				if effectFunc then
					local conn = effectFunc(newLabel, data)
					if conn then
						table.insert(Controller._activeConnections, conn)
					end
				end
			end
			
			data.Instance = newLabel
			Controller.OnLetterTyped:Fire(data)

			local waitTime = Config.DefaultTypeSpeed

			local chr = data.Letter
			if table.find(commaList, chr) then waitTime += Config.CommaPauseLength end
			if table.find(puncList, chr) then waitTime += Config.PunctuationPauseLength end

			if not skipped then
				if (chr == " " and Config.PlaySoundOnSpace) or chr ~= " " then
					playTypeSound()
				end
				task.wait(waitTime)
			end
		end

		Controller.Completed:Fire()
		Layout:Destroy()

	end)

	return Controller
end

function Typewriter:TypeInLabel(targetLabel : TextLabel, text : string)

	local Controller = {

		OnLetterTyped = signal(),-- gives {Letter : string, Index : number}
		Completed = signal(),

	}

	local skipped = false
	local cancelled = false

	function Controller:Skip() skipped = true end
	function Controller:Cancel() cancelled = true end
	function Controller:Destroy()
		for i, v in Controller do
			Controller[i] = nil
		end
		Controller = nil
	end

	task.spawn(function()
		
		local data, stripped = parse(text)
		targetLabel.Text = text
		targetLabel.MaxVisibleGraphemes = 0

		local contentText = targetLabel.ContentText

		for i in utf8.graphemes(contentText) do
			if cancelled then return end

			targetLabel.MaxVisibleGraphemes = i

			local chr = contentText:sub(i, i)
			Controller.OnLetterTyped:Fire({Letter = chr, Index = i})

			if not skipped then
				if (chr == " " and Config.PlaySoundOnSpace) or chr ~= " " then
					playTypeSound()
				end

				local waitTime = Config.DefaultTypeSpeed
				if table.find(commaList, chr) then waitTime += Config.CommaPauseLength end
				if table.find(puncList, chr) then waitTime += Config.PunctuationPauseLength end

				task.wait(waitTime)
			end
		end

		targetLabel.MaxVisibleGraphemes = -1
		Controller.Completed:Fire()
		
	end)

	return Controller
end

---<>--- Initialization ---<>---

function Typewriter:Init()

	for _, effect in effectFolder:GetChildren() do
		if effect:IsA("ModuleScript") then
			local req = require(effect)
			loadedEffects[effect.Name] = req
		end
	end

end

return Typewriter