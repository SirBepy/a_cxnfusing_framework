--[[
	Purpose:
		Minimal "replace Motor6Ds with BallSocketConstraints" ragdoll. Disables
		the motors, parents sockets in their place, and drops the humanoid into
		PlatformStand so physics takes over. Stop reverses it.

	When to use:
		Death flops, getting hit by a car, knockback/stun states. Anywhere you
		want a body to go limp and respond to physics instead of animation.

	Example:
		Ragdoll.Start(character)
		task.wait(3)
		Ragdoll.Stop(character)

	Gotchas:
		- Sets a "Ragdolling" attribute on the character to dedupe calls; Stop
		  clears it.
		- TwistLimits of +/-90 are a reasonable default for all joints; tune per
		  joint if your character has specific needs (neck, wrists).
		- Stop disables the Ragdoll HumanoidState after forcing GettingUp; that
		  last :SetStateEnabled call is intentional to prevent Roblox's built-in
		  state machine from snapping back into Ragdoll on its own.
		- Currently leaks the two Attachments created per Motor6D on Stop.
]]

local ragdoll = {}

function ragdoll.Start(character : Model)
	
	-- Attribute-based dedupe: stops double-ragdolling from adding a second set
	-- of BallSocketConstraints (which would immediately fight each other).
	if character:GetAttribute("Ragdolling") then return end
	character:SetAttribute("Ragdolling", true)
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	for i,v in pairs(character:GetDescendants()) do
		if v:IsA("Motor6D") then
			
			local socket = Instance.new("BallSocketConstraint")
			
			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")
			
			a0.Parent = v.Part0
			a1.Parent = v.Part1
			
			socket.Parent = v.Parent
			
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			
			-- Inherit the Motor6D's C0/C1 so the socket hinges at exactly the
			-- same pivot points the animation rig was using. Without this the
			-- limbs would snap to arbitrary offsets when physics takes over.
			a0.CFrame = v.C0
			a1.CFrame = v.C1
			
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.TwistUpperAngle = 90
			socket.TwistLowerAngle = -90

			v.Enabled = false
			
		end
	end

	-- Kill locomotion + auto-rotate so the humanoid doesn't fight the sockets,
	-- and PlatformStand hands control over to physics. BreakJointsOnDeath is
	-- off so dying mid-ragdoll doesn't explode the rig into gibs.
	humanoid.BreakJointsOnDeath = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	
	humanoid:ChangeState(Enum.HumanoidStateType.Ragdoll)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)	

end

function ragdoll.Stop(character : Model)
	
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end
	
	character:SetAttribute("Ragdolling", false)
	
	for i,v in pairs(character:GetDescendants()) do
		if v:IsA("BallSocketConstraint") then
			v:Destroy()
		end
		if v:IsA("Motor6D") then
			v.Enabled = true
		end
	end
	
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.AutoRotate = true
	humanoid.PlatformStand = false
	
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)	
	
end

return ragdoll