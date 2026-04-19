--[[
	Typewriter

	Purpose:
		Renders text one character at a time. Two modes:
		  - :Type(text)           - spawns a TextLabel PER letter inside
		                            Config.TypeFrame. Slower, but lets
		                            per-letter effects (wave, rainbow,
		                            glitch, etc.) work via the <effect>
		                            tags in the input text.
		  - :TypeInLabel(lbl, t)  - uses MaxVisibleGraphemes on a single
		                            TextLabel. Fast and simple, but
		                            effect tags won't animate.

	When to use:
		The DialogueHandler picks between these based on its Config
		.TextType ("Letter" vs "InLabel"). You can also drive the
		Typewriter directly if you want typed text outside dialogue,
		e.g. a narration box or a cutscene caption.

	Example:
		local Typewriter = require(path.to.Typewriter)
		Typewriter:Init() -- loads effect modules once at startup

		Typewriter:SetConfig({
			TypeFrame         = myLetterFrame,
			LetterTemplate    = myLetterTemplate,
			TypeSound         = mySound,
			SoundStacks       = true,
			PitchVariation    = {0.95, 1.05},
			PlaySoundOnSpace  = false,
			DefaultTypeSpeed  = 0.03,
			CommaPauseLength  = 0.2,
			PunctuationPauseLength = 0.5,
		})

		local tw = Typewriter:Type("Hello <wave>world</wave>!")
		tw.OnLetterTyped:Connect(function(data)
			print("typed:", data.Letter, "at", data.Index)
		end)
		tw.Completed:Wait()

	Gotchas:
		- Call :Init() ONCE before typing, so effect modules in Effects/
		  are loaded. If you skip it, effect tags parse but do nothing.
		- :SetConfig MERGES into the live Config (doesn't replace it).
		  Reset manually if you need a clean slate.
		- :Type hard-requires Config.TypeFrame. It warns and returns nil
		  otherwise.
		- Index passed to OnLetterTyped counts VISIBLE characters (tags
		  stripped), which is what DialogueHandler keys commands against.
		- Layout is a naive left-to-right word-wrapper; it measures each
		  word with TextService. Fine for short lines, not a full rich
		  text engine.
--]]

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

	-- SoundStacks=true means each keystroke clones the sound so rapid
	-- typing overlaps instead of retriggering the same instance (which
	-- would restart playback and sound choppy).
	local playback = sound
	if Config.SoundStacks then
		playback = sound:Clone()
		playback.Parent = sound.Parent
		playback.Stopped:Connect(function() playback:Destroy() end)
	end

	local pitchEffect = playback:FindFirstChild("PitchShiftSoundEffect") or Instance.new("PitchShiftSoundEffect", playback)
	-- Random per-letter pitch makes the typing sound feel alive. Scale
	-- to integers for math.random then divide back down to the decimal
	-- range the user configured.
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
	-- `parse` strips <effect> tags and returns the visible characters +
	-- which effects are active at each index. `stripped` is the clean
	-- string used by the layout engine for word-wrap measurement.
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
			-- :Wait(n) pauses the typing loop without killing it, so
			-- $wait:0.5$ in a dialogue line can create dramatic pauses.
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