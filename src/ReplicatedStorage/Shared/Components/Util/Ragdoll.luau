local ragdoll = {}

function ragdoll.Start(character : Model)
	
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
			
			a0.CFrame = v.C0
			a1.CFrame = v.C1
			
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.TwistUpperAngle = 90
			socket.TwistLowerAngle = -90

			v.Enabled = false
			
		end
	end

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