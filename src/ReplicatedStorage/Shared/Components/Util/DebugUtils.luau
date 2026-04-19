local DebugUtils = {}

local debugParent = workspace:FindFirstChild("Debug") or Instance.new("Folder", workspace)
debugParent.Name = "Debug"

-- Safe function call: catches errors, logs them
function DebugUtils.SafeCall(func, ...)
	local ok, err = pcall(func, ...)
	if not ok then
		warn("[SafeCall Error] "..tostring(err))
	end
end

-- Times a block of code
function DebugUtils.TimeBlock(label, func)
	local start = tick()
	local ok, err = pcall(func)
	local elapsed = (tick() - start) * 1000
	if not ok then warn("[TimeBlock Error] "..tostring(err)) end
	print(string.format("[TimeBlock] %s -> %.2f ms", label, elapsed))
end

-- Prints all attributes and children of an instance nicely
function DebugUtils.ProfileInstance(inst)
	if not inst or not inst:IsA("Instance") then return end
	print("---- Profile:", inst:GetFullName(), "----")
	for _, attr in ipairs(inst:GetAttributes()) do
		print("Attribute:", attr, inst:GetAttribute(attr))
	end
	for _, child in ipairs(inst:GetChildren()) do
		print("Child:", child.Name, child.ClassName)
	end
	print("---- End Profile ----")
end

local function newPart()

	local p = Instance.new("Part")
	p.Parent = debugParent
	p.Material = Enum.Material.Neon
	p.Transparency = 0.5
	p.CanCollide = false
	p.CanQuery = false
	p.Anchored = true

	return p	
end

function DebugUtils.NewLine(from : Vector3, to : Vector3, config : {lifetime : number, color : Color3, thickness : number, transparency : number})
	config = config or {}
	config.lifetime = config.lifetime or 10

	local p = newPart()

	p.CFrame = CFrame.new((from+to)/2, to)
	p.Size = Vector3.new(config.thickness or 0.1, config.thickness or 0.1,(from-to).Magnitude)
	p.Color = config.color or Color3.new(1,0,0)
	p.Transparency = config.transparency or 0.5

	if config.lifetime and config.lifetime > 0 then
		game.Debris:AddItem(p, config.lifetime)
	end

	return p
end

function DebugUtils.NewSphere(at : Vector3, config : {lifetime : number, color : Color3, size : number, transparency : number})
	config = config or {}
	config.lifetime = config.lifetime or 10

	local p = newPart()

	p.Shape = Enum.PartType.Ball
	p.Position = at or Vector3.zero
	p.Size = Vector3.one*(config.size or 1)
	p.Color = config.color or Color3.new(0,1,0)
	p.Transparency = config.transparency or 0.5

	if config.lifetime and config.lifetime > 0 then
		game.Debris:AddItem(p, config.lifetime)
	end

	return p
end

function DebugUtils.NewBox(at : CFrame, config : {lifetime : number, color : Color3, size : Vector3, transparency : number})
	config = config or {}
	config.lifetime = config.lifetime or 10

	local p = newPart()

	p.Shape = Enum.PartType.Ball
	p.CFrame = at or CFrame.new(0,0,0)
	p.Size = config.size or Vector3.one*2
	p.Color = config.color or Color3.new(0,1,0)
	p.Transparency = config.transparency or 0.5

	if config.lifetime and config.lifetime > 0 then
		game.Debris:AddItem(p, config.lifetime)
	end

	return p
end

return DebugUtils