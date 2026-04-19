local VFX = {}

---<>--- Variables ---<>---

type VFXEvent = {
	FireServer: (self: any, action: string, data: any) -> (),
	FireClient: (self: any, plr: Player, action: string, data: any) -> (),
	FireAllClients: (self: any, action: string, data: any) -> (),
	Connect: (self: any, callback: (any) -> ()) -> (),
}

local rs = game.ReplicatedStorage

local emitter = require(script.Emitter)
local pooler = require(script.Parent.Parent:WaitForChild("Util")).Pool

local vfxAssets = rs:WaitForChild("Assets"):WaitForChild("VFX")

local VFXGlobalEvent : VFXEvent
local VFXLocalEvent : VFXEvent

local customEffects = script.CustomEffects
local loadedEffects = {}

local vfxPools = {}
local vfxDefaults = {}

local isClient = game:GetService("RunService"):IsClient()

local wVFX = workspace:FindFirstChild("VFX") or
	(not isClient and Instance.new("Folder", workspace))
	or workspace:WaitForChild("VFX")
wVFX.Name = "VFX"
local rVFX = rs:FindFirstChild("VFXStorage") or
	(not isClient and Instance.new("Folder", rs))
	or rs:WaitForChild("VFXStorage")
rVFX.Name = "VFXStorage"

---<>--- Helpers ---<>---

local function getVFX(particleName : string) : (Instance, typeof(vfxPools[1]))

	local foundPool = vfxPools[particleName]
	if not foundPool then return end
	local obj = foundPool:Get()

	return obj, foundPool
end

--Server Side Replication
local function sendToClients(action : string, data : {Recipients : {Player}})
	if data.Recipients then
		for _, plr in data.Recipients do
			VFXGlobalEvent:FireClient(plr, action, data)
		end
	else
		VFXGlobalEvent:FireAllClients(action, data)
	end
end

local function getConfig(vfxModel, passedData)
	local finalConfig = {}
	local config = vfxModel:FindFirstChildOfClass("Configuration")

	if config then
		for _, val in config:GetChildren() do
			if val:IsA("ValueBase") then
				finalConfig[val.Name] = val.Value
			end
		end
	end

	for key, value in passedData do
		finalConfig[key] = value
	end

	return finalConfig
end

---<>--- Main Functionality ---<>---

local function onEvent(action : string, data : {

	VFXName : string,
	Looped : boolean,

	Destroy : boolean,
	DestroyAfter : number,

	Parent : Instance,
	Position : Vector3,
	CFrame : CFrame,
	UseLocalAttachmentCF : boolean,

	})

	if action == "New" then

		local VFXName = data.VFXName
		local new, pool = getVFX(VFXName)

		if new and pool then

			local config = getConfig(new, data)

			local cf = config.CFrame or (config.Position and CFrame.new(config.Position)) or CFrame.new(0,0,0)
			if new:IsA("Model") then
				new:PivotTo(cf)
			elseif new:IsA("BasePart") then
				new.CFrame = cf
			elseif new:IsA("Attachment") then
				if data.UseLocalAttachmentCF then
					new.CFrame = cf
				else
					new.WorldCFrame = cf
				end
			end

			new.Parent = config.Parent or wVFX

			local custom = loadedEffects[VFXName] :: (Instance, {})->()
			local customResult = custom and custom(new, config)
			
			local emitAnyways = (customResult ~= nil and customResult)
			if emitAnyways == nil or not custom then emitAnyways = true end
			
			if emitAnyways then
				if config.Looped then
					emitter:LoopEmitAll(new, config.DestroyAfter, pool)
				else
					emitter:EmitAll(new, config.Destroy, pool)
				end
			end

		end
	end

end

function VFX.newVFX(data : {

	VFXName : string,
	Looped : boolean,

	Destroy : boolean,
	DestroyAfter : number,

	Parent : Instance,
	Position : Vector3,
	CFrame : CFrame,
	UseLocalAttachmentCF : boolean,

	Replicate : boolean,
	Recipients : {Player},

	})
	if not data or not data.VFXName then return end
	data = data or {}

	if isClient then--                  //Client Side
		if data.Replicate then
			VFXGlobalEvent:FireServer("New", data)--    Send data to Server to replicate
		else
			VFXLocalEvent:Fire("New", data)--           Run only on our Client
		end
	else--                                          //Server Side
		sendToClients("New", data)
	end

end

---<>--- Initialization ---<>----

function VFX:Init()

	local Shared = require(script.Parent.Parent.Parent) :: any
	VFXGlobalEvent = Shared.GlobalEvents.VFX
	VFXLocalEvent = Shared.LocalEvents.VFX

	for _, vfx in vfxAssets:GetChildren() do

		for _, desc in vfx:GetDescendants() do
			if desc:IsA("ParticleEmitter") or desc:IsA("Light") then
				desc:SetAttribute("DefaultEnabled", desc.Enabled)
			end
		end

		local name = vfx.Name

		local pool = pooler:CreatePool(
			name, 
			function()
				return vfx:Clone()
			end,
			function(obj : typeof(vfx))

				obj.Parent = rVFX

				for i, desc in obj:GetDescendants() do
					local on = false
					local default = desc:GetAttribute("DefaultEnabled") :: boolean?
					if default ~= nil then on = default end 
					if desc:IsA("ParticleEmitter") then
						desc.Enabled = on
						desc:Clear()
					elseif desc:IsA("Light") then
						desc.Enabled = on
					end
				end

			end,
			nil,
			{preloadCount = 2}
		)

		vfxPools[name] = pool
		vfxDefaults[name] = vfx

	end

	if isClient then--      //Client Side

		VFXGlobalEvent:Connect(onEvent)
		VFXLocalEvent:Connect(onEvent)

		for _, effect in customEffects:GetChildren() do
			if effect:IsA("ModuleScript") then
				local func = require(effect)
				loadedEffects[effect.Name] = func
			end
		end

	else--                              //Server Side
		VFXGlobalEvent:Connect(function(plr : Player, action : string, data)
			sendToClients(action, data)
		end)
	end

end

return VFX