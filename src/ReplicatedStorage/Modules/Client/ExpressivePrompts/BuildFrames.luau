--[[
	BuildFrames
	-----------
	Purpose:
		Builds the CanvasGroup "card" behind each prompt plus the nested frames
		that host the input glyph. All animations (size squish on hold, subtle
		rotation, aspect-ratio morph, shimmer sweep, progress bar) live here.

	When to use:
		Internal helper for ExpressivePrompts/init.luau. Not meant to be called
		from user code.

	Example:
		local Frame, ResizeableInputFrame = unpack(BuildFrames(PromptScope, Seam, ...))

	Gotchas:
		- Every reactive prop uses Seam Springs/Computeds - don't replace them
		  with raw tweens or the ButtonHeldDown feedback loop breaks.
		- Returns {Frame, ResizeableInputFrame} as an array; caller unpacks.

	Seam note:
		Built on the vendored Seam library. See module docs for a tutorial on
		Scope:New, Computed, and Spring if any of this looks alien.
]]
return function(Scope : any, Seam : any, Config : {}, PromptUI, ButtonHeldDown, PromptTransparency, AspectRatioValue, CurrentBarSize, CurrentFrameScaleFactor) : {any}
	-- CanvasGroup (not Frame) so GroupTransparency fades children in one pass.
	local Frame = Scope:New("CanvasGroup", {
		-- Squish to half-width while held so the glyph pops forward visually.
		-- Scope:Computed(fn) is Seam's derived value: whenever any Use()'d
		-- dependency changes, the function re-runs and downstream bindings
		-- pick up the new value.
		Size = Scope:Spring(Scope:Computed(function(Use)
			return Use(ButtonHeldDown) and UDim2.fromScale(0.5, 1) or UDim2.fromScale(1, 1)
		end), Config.MainSizeSpringSpeed, Config.MainSizeSpringDampening),

		-- Tilt one way at rest, snap to 0 while visible, tilt the other way
		-- while held. Gives the card a bit of personality on every state change.
		Rotation = Scope:Spring(Scope:Computed(function(Use)
			local RotationStrength = Use(Config.MainRotationStrength)

			if Use(ButtonHeldDown) then
				return -RotationStrength
			elseif Use(PromptTransparency) < 1 then
				return 0
			else
				return RotationStrength
			end
		end), Config.MainRotationSpringSpeed, Config.MainRotationSpringDampening),
		
		BackgroundTransparency = Config.BackgroundTransparency,
		-- GroupTransparency fades the entire card (children included) as a unit.
		-- Critical damping (1.0) so no overshoot on fade.
		GroupTransparency = Scope:Spring(PromptTransparency, 30, 1),
		BackgroundColor3 = Config.BackgroundColor,
		Parent = PromptUI,

		-- Seam.Children is the "these are my kids" key in the props table.
		[Seam.Children] = {
			Scope:New("UICorner", {
				CornerRadius = Scope:Computed(function(Use)
					return UDim.new(0, Use(Config.CornerRadius))
				end),
			}),

			-- While held, snap to a square so the card reads as "pressed"
			-- regardless of how wide the text made it.
			Scope:New("UIAspectRatioConstraint", {
				AspectRatio = Scope:Spring(Scope:Computed(function(Use)
					return Use(ButtonHeldDown) and 1 or Use(AspectRatioValue)
				end), Config.AspectRatioSpringSpeed, Config.AspectRatioSpringDampening),
			}),

			Scope:New("Frame", {
				Name = "ProgressBar",
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BorderSizePixel = 0,
				BackgroundColor3 = Config.ProgressBarColor,
				BackgroundTransparency = Config.ProgressBarTransparency,
				Size = Scope:Computed(function(Use)
					return UDim2.fromScale(Use(CurrentBarSize), Use(Config.ProgressBarYScale))
				end),
			}),

			-- Shimmer sweep: a diagonal gradient whose Offset slides from -1
			-- to 1 each time the prompt appears, reading as a light flash.
			Scope:New("UIGradient", {
				Rotation = 45,
				Enabled = Config.ShowShimmer,

				Transparency = NumberSequence.new{
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.5, 0.5),
					NumberSequenceKeypoint.new(1, 0),
				},

				Offset = Scope:Spring(Scope:Computed(function(Use)
					return Use(PromptTransparency) < 1 and Vector2.new(1, 0) or Vector2.new(-1, 0)
				end), 8, 1),
			}),
		},
	})

	-- RelativeYY keeps the input area square regardless of card width, so
	-- the glyph doesn't stretch when ActionText gets long.
	local InputFrame = Scope:New("Frame", {
		Name = "InputFrame",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Parent = Frame,
	})

	-- Second layer so the UIScale "press bounce" doesn't fight the parent's
	-- layout constraints; only this inner frame scales on hold.
	local ResizeableInputFrame = Scope:New("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = InputFrame,

		[Seam.Children] = {
			Scope:New("UIScale", {
				Scale = Scope:Spring(CurrentFrameScaleFactor, 20, 0.7),
			}),

			Scope:New("Frame", {
				Name = "RoundFrame",
				Size = UDim2.fromOffset(48, 48),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
		
				[Seam.Children] = {
					Scope:New("UICorner", {
						CornerRadius = UDim.new(0.5, 0),
					}),
				}
			})
		}
	})

	return {Frame, ResizeableInputFrame}
end