--[[
	NewInputConnections
	-------------------
	Purpose:
		Wires up all the behavioral signals for a single prompt: plays the
		appear/click/hold/trigger sounds, drives the hold-progress bar, and
		flips ButtonHeldDown so the UI can react.

	When to use:
		Internal to ExpressivePrompts. Returns a list of RBXScriptConnections
		that the caller hands to the scope so they die with the prompt.

	Example:
		local InputConnections = NewInputConnections(Scope, { prompt = ..., ButtonHeldDown = ..., ... })

	Gotchas:
		- HOLD_SOUND.PlaybackSpeed is set without a nil-guard - if PlaySound
		  fails to create the sound (e.g. asset unavailable) this line errors.
		  Known, intentionally left for the review.
		- HoldStart is captured at module entry but only reset inside
		  PromptButtonHoldBegan, so the RenderStepped TimeHeldDown value is
		  stale for any period before the first hold begins. Also known.
		- Sound instances are looked up on SoundService by SoundId-as-name
		  rather than by ref, so name collisions between callers are possible.

	Seam note:
		We only use Seam's Scope here - the connections themselves are stock
		Roblox signals. See the module docs for a Seam walkthrough.
]]

-- Types
type Properties = {
    prompt: ProximityPrompt,
    ButtonHeldDown: any,
    CurrentBarSize: any,
    CurrentFrameScaleFactor: any,
    PromptTransparency: any,
    InputFrameScaleFactor: any,
}

-- Constants
local APPEAR_SOUND = "rbxassetid://10066931761"
local CLICK_SOUND = "rbxassetid://10128760939"
local HOLD_SOUND = "rbxassetid://421058925"
local TRIGGER_SOUND = "rbxassetid://10128766965"

-- Services
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Reuse one Sound per SoundId by stashing it under SoundService named by the
-- asset id. Cheap de-dupe so we don't spawn a new Sound each prompt.
local function PlaySound(Scope : any, SoundId : string, Properties : {[string]: any}?)
	local Sound = SoundService:FindFirstChild(SoundId)

	if not Sound then
		Sound = Scope:New(Scope:New("Sound", {
			Name = SoundId,
			SoundId = SoundId,
			Volume = 0.35,
			Parent = SoundService,
		}), Properties or {})
	end

	Sound:Play()
end

local function StopSound(SoundId)
	local Sound = SoundService:FindFirstChild(SoundId)

	if Sound then
		Sound:Stop()
	end
end

return function(Scope : any, Properties : Properties) : {RBXScriptConnection}
    local InputConnections = {}
	local HoldStart = os.clock()

	PlaySound(Scope, APPEAR_SOUND)

	-- HoldDuration > 0 means "press and hold to activate"; 0 means instant trigger.
	if Properties.prompt.HoldDuration > 0 then
		-- Drive the progress bar Value forward by dt/HoldDuration while held,
		-- and ramp up the hold sound's pitch so it feels like it's winding up.
		InputConnections[#InputConnections + 1] = RunService.RenderStepped:Connect(function(deltaTime)
			local TimeHeldDown = os.clock() - HoldStart

			if Properties.ButtonHeldDown.Value then
				Properties.CurrentBarSize.Value = math.min(Properties.CurrentBarSize.Value + deltaTime / Properties.prompt.HoldDuration, 1)

				SoundService:FindFirstChild(HOLD_SOUND).PlaybackSpeed = 0.5 + TimeHeldDown
			else
				Properties.CurrentBarSize.Value = 0
			end
		end)

		InputConnections[#InputConnections + 1] = Properties.prompt.PromptButtonHoldBegan:Connect(function()
			HoldStart = os.clock()
			PlaySound(Scope, HOLD_SOUND, {
				Looped = true,
				Volume = 0.2,
			})
			PlaySound(Scope, CLICK_SOUND)
			Properties.ButtonHeldDown.Value = true
			Properties.CurrentFrameScaleFactor.Value = Properties.InputFrameScaleFactor
		end)

		InputConnections[#InputConnections + 1] = Properties.prompt.PromptButtonHoldEnded:Connect(function()
			StopSound(HOLD_SOUND)
			Properties.ButtonHeldDown.Value = false
			Properties.CurrentFrameScaleFactor.Value = 1
		end)
	end

	InputConnections[#InputConnections + 1] = Properties.prompt.Triggered:Connect(function()
		if Properties.prompt.HoldDuration > 0 then
			-- Hold-prompt success: just the meaty trigger SFX; UI already
			-- animated via PromptButtonHoldBegan/Ended above.
			PlaySound(Scope, TRIGGER_SOUND)
		else
			-- Tap-style prompt has no hold state, so we fake a one-frame
			-- "press" to drive the squish/tilt/text-fade for visual feedback.
			PlaySound(Scope, CLICK_SOUND)
			Properties.ButtonHeldDown.Value = true

			task.delay(1 / 60, function()
                Properties.ButtonHeldDown.Value = false
			end)
		end
	end)

    return InputConnections
end