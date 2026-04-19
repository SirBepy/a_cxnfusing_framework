--[[
	ExpressivePrompts - entry point
	-------------------------------
	Purpose:
		Replaces Roblox's default ProximityPrompt UI with a bouncy, animated,
		fully-themeable version. Drop it in, call Init() once on the client,
		and every non-Default-style ProximityPrompt in the game gets our UI.

	When to use:
		Any client-side script that wants prettier prompts. ReplicatedFirst is
		a fine place to kick it off since we wait on game.Loaded below.

	Example:
		local ExpressivePrompts = require(path.to.ExpressivePrompts)
		ExpressivePrompts.Config.BackgroundColor:set(Color3.new(0.1, 0.1, 0.2))
		ExpressivePrompts:Init()

	Gotchas:
		- Init() is single-shot. Calling it twice just warns and bails.
		- Config values are Seam Values, not raw Lua values. Read/write them
		  through the Seam API (:set, etc) so bindings stay reactive.
		- We leave Default-style prompts alone by flipping them to Custom and
		  briefly reparenting them, so no overlapping UI shows up.

	Note on Seam:
		This module is built on the vendored Seam UI library (a Fusion-style
		reactive UI toolkit). If terms like Scope, Value, Computed, Spring,
		New, Children, or OnEvent are new to you, skim Seam's docs first, then
		come back. See this module's own docs page for a walkthrough tutorial.
]]

--[=[
	Customizable UI that replaces the default for ProximityPrompt instances.

	Below are the config entries:

	```
	Config.BackgroundTransparency number -- The background transparency
	Config.BackgroundColor Color3 -- The background color
	Config.TextColor Color3 -- The text and icon color
	Config.SubTextColor Color3 -- The sub text color
	Config.CornerRadius number -- The corner radius on the main background
	Config.MainSizeSpringSpeed number -- The spring speed for the main size animation
	Config.MainSizeSpringDampening number -- The spring dampening for the main size animation
	Config.MainRotationSpringSpeed number -- The spring speed for the main rotation animation
	Config.MainRotationSpringDampening number -- The spring dampening for the main rotation animation
	Config.MainRotationStrength number -- How far the main frame can rotate
	Config.AspectRatioSpringSpeed number -- The spring speed for the aspect ratio animation
	Config.AspectRatioSpringDampening number -- The spring dampening for the aspect ratio animation
	Config.ProgressBarYScale number -- The Y scale (0-1) of the progress bar size
	Config.ProgressBarColor -- The color of the progress bar
	Config.ProgressBarTransparency number -- The transparency of the progress bar
	Config.ShowShimmer boolean -- Whether the shimmer effect plays when the prompt appears
	Config.GuiOffsetSpringSpeed number -- The spring speed for the BillboardGui animation
	Config.GuiOffsetSpringDampening number -- The spring dampening for the BillboardGui animation
	```

	@class ExpressivePrompts
]=]

--[=[
	@class 
]=]

local ExpressivePrompts = {}

-- Services
local ProximityPromptService = game:GetService("ProximityPromptService")
local PlayersService = game:GetService("Players")

if not game:IsLoaded() then -- Useful for when loading this from a script in ReplicatedFirst
	game.Loaded:Wait()
end

-- Imports
local Packages = script:FindFirstChild("Packages")
local Seam = if Packages then require(Packages.Seam) else require(script.Parent.Seam)
local NewInputLabel = require(script.NewInputLabel)
local NewInputConnections = require(script.NewInputConnections)
local BuildTextLabels = require(script.BuildTextLabels)
local BuildFrames = require(script.BuildFrames)
local UpdateUIFromPrompt = require(script.UpdateUIFromPrompt)

-- Variables
-- A Seam Scope is the lifecycle container for every Value/Instance we spawn.
-- Destroying the scope tears everything down; we keep this top-level one alive
-- for the lifetime of the module and spin off InnerScopes per prompt.
local Scope = Seam.Scope(Seam)
local Player = PlayersService.LocalPlayer
local Gui = nil

-- Config
-- Each config field is a Seam Value so that UI bindings update live when a
-- game script calls :set() on one of them (e.g. re-theming at runtime).
ExpressivePrompts.Config = {
	BackgroundTransparency = Scope:Value(0.5),
	BackgroundColor = Scope:Value(Color3.new(0.07, 0.07, 0.07)),
	TextColor = Scope:Value(Color3.new(1, 1, 1)),
	SubTextColor = Scope:Value(Color3.new(0.7, 0.7, 0.7)),
	CornerRadius = Scope:Value(16),
	MainSizeSpringSpeed = Scope:Value(20),
	MainSizeSpringDampening = Scope:Value(0.4),
	MainRotationSpringSpeed = Scope:Value(30),
	MainRotationSpringDampening = Scope:Value(0.1),
	MainRotationStrength = Scope:Value(5),
	AspectRatioSpringSpeed = Scope:Value(20),
	AspectRatioSpringDampening = Scope:Value(0.4),
	ProgressBarYScale = Scope:Value(0.1),
	ProgressBarColor = Scope:Value(Color3.new(1, 1, 1)),
	ProgressBarTransparency = Scope:Value(0.5),
	ShowShimmer = Scope:Value(true),
	GuiOffsetSpringSpeed = Scope:Value(15),
	GuiOffsetSpringDampening = Scope:Value(0.5),
}

-- Captures the UpdateUIFromPrompt args once so we can hand the Prompt.Changed
-- signal a zero-arg listener that still calls the updater with everything.
local function GetUpdateCallback(...)
	local Args = {...}

	return function()
		UpdateUIFromPrompt(unpack(Args))
	end
end

local function CreatePrompt(Prompt : ProximityPrompt, InputType : Enum.ProximityPromptInputType)
	-- InnerScope gives this prompt its own lifecycle. When the prompt hides we
	-- Destroy() this scope and every Instance/Value/connection it owns dies.
	local PromptScope = Scope:InnerScope()
	-- Touch gets a bigger "pressed" scale because fingers are bigger than cursors.
	local InputFrameScaleFactor = InputType == Enum.ProximityPromptInputType.Touch and 1.6 or 1.33
	local CurrentFrameScaleFactor = PromptScope:Value(1)
	local PromptTransparency = PromptScope:Value(1)
	local ButtonHeldDown = PromptScope:Value(false)
	local AspectRatioValue = PromptScope:Value(1)
	local CurrentBarSize = PromptScope:Value(0)

	local InputConnections : {RBXScriptConnection} = NewInputConnections(Scope, {
		prompt = Prompt,
		ButtonHeldDown = ButtonHeldDown,
		CurrentBarSize = CurrentBarSize,
		CurrentFrameScaleFactor = CurrentFrameScaleFactor,
		PromptTransparency = PromptTransparency,
		InputFrameScaleFactor = InputFrameScaleFactor,
	})

	-- Scope:New is Seam's "build an Instance with these props" primitive. Any
	-- prop can be a raw value, a Value, a Computed, or a Spring - Seam wires
	-- up the reactivity for us.
	local PromptUI : BillboardGui = PromptScope:New("BillboardGui", {
		Name = `Prompt_{Prompt:GetFullName()}`,
		AlwaysOnTop = true,
		Parent = Gui,
		Adornee = Prompt.Parent,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		-- Slide the gui in from the side by springing the StudsOffset between
		-- (-1,0,0) when hidden and (0,0,0) when shown. The Spring wrapper gives
		-- that juicy overshoot without us writing tween code.
		StudsOffset = PromptScope:Spring(PromptScope:Computed(function(Use)
			return Use(PromptTransparency) < 1 and Vector3.new(0, 0, 0) or Vector3.new(-1, 0, 0)
		end), ExpressivePrompts.Config.GuiOffsetSpringSpeed, ExpressivePrompts.Config.GuiOffsetSpringDampening)
	})

	local Frame : CanvasGroup, ResizeableInputFrame : Frame = unpack(BuildFrames(
		PromptScope,
		Seam,
		ExpressivePrompts.Config,
		PromptUI,
		ButtonHeldDown,
		PromptTransparency,
		AspectRatioValue,
		CurrentBarSize,
		CurrentFrameScaleFactor
	))

	local ActionText : TextLabel, ObjectText : TextLabel = unpack(BuildTextLabels(
		PromptScope,
		ExpressivePrompts.Config,
		Frame,
		ButtonHeldDown
	))

	-- Seam.Children is the magic key that says "these are my kids". We pass
	-- the platform-appropriate key/button label (keyboard glyph, gamepad icon,
	-- or touch tap icon) into the round frame built above.
	PromptScope:New(ResizeableInputFrame, {
		[Seam.Children] = NewInputLabel(PromptScope, InputType, Prompt, ExpressivePrompts.Config)
	})

	-- Touch devices always need a tap target; non-touch only gets one when the
	-- developer opted into ClickablePrompt on the ProximityPrompt itself.
	if InputType == Enum.ProximityPromptInputType.Touch or Prompt.ClickablePrompt then
		local IsButtonDown = false

		PromptScope:New(PromptUI, {
			Active = true,

			[Seam.Children] = {
				PromptScope:New("TextButton", {
					BackgroundTransparency = 1,
					TextTransparency = 1,
					Size = UDim2.fromScale(1, 1),
		
					-- Seam's OnEvent lets us bind to an Instance signal right
					-- inside the props table. It auto-disconnects when the
					-- scope dies, so we don't have to track the connection.
					[PromptScope:OnEvent "InputBegan"] = function(input)
						if
							(
								input.UserInputType == Enum.UserInputType.Touch
								or input.UserInputType == Enum.UserInputType.MouseButton1
							) and input.UserInputState ~= Enum.UserInputState.Change
						then
							Prompt:InputHoldBegin()
							IsButtonDown = true
						end
					end,
		
					[PromptScope:OnEvent "InputEnded"] = function(input)
						if
							input.UserInputType == Enum.UserInputType.Touch
							or input.UserInputType == Enum.UserInputType.MouseButton1
						then
							if IsButtonDown then
								IsButtonDown = false
								Prompt:InputHoldEnd()
							end
						end
					end,
				})
			}
		})
	end

	local UpdateCallback = GetUpdateCallback(
		PromptScope,
		Prompt,
		PromptUI,
		AspectRatioValue,
		ActionText,
		ObjectText
	)

	-- Re-run the updater whenever any prompt property changes (ActionText,
	-- ObjectText, UIOffset, etc.) so the UI stays in sync with dev tweaks.
	InputConnections[# InputConnections+1] = Prompt.Changed:Connect(UpdateCallback)
	UpdateCallback()
	-- Kick off the fade-in: 1 = hidden, 0 = fully visible. Springs handle the rest.
	PromptTransparency.Value = 0

	-- Hand raw RBX connections to the scope so :Destroy() disconnects them.
	for _, Connection in InputConnections do
		PromptScope:AddObject(Connection)
	end

	-- Returned closure is called by PromptHidden. We animate out first, then
	-- destroy after a short delay so the fade/slide actually plays.
	return function()
		ButtonHeldDown.Value = false
		PromptTransparency.Value = 1

		task.delay(2, function()
			PromptScope:Destroy()
		end)
	end
end

--[=[
	Initializes ExpressivePrompts. Call only one time.
]=]

function ExpressivePrompts:Init()
	if Gui then
		warn("Attempted to call ExpressivePrompts:Init(); already initialized by another script")
		return
	end

	Gui = Scope:New("ScreenGui", {
		Name = "ExpressivePromptsGui",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Parent = Player:WaitForChild("PlayerGui"),
	})

	ProximityPromptService.PromptShown:Connect(function(Prompt : ProximityPrompt, InputType : Enum.ProximityPromptInputType)
		if Prompt.Style == Enum.ProximityPromptStyle.Default then
			-- Default-style prompts get Roblox's built-in UI which would stack
			-- on top of ours. Flip to Custom and bounce the parent so the
			-- service re-fires PromptShown with the new style - no overlap.
			local LastParent = Prompt.Parent

			Prompt.Style = Enum.ProximityPromptStyle.Custom
			Prompt.Parent = nil

			task.defer(function()
				Prompt.Parent = LastParent
			end)

			return
		end

		local CleanupFunction = CreatePrompt(Prompt, InputType)

		Prompt.PromptHidden:Once(CleanupFunction)
	end)
end

return ExpressivePrompts