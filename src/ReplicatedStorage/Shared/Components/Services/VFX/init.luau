--[[
	VFX Service -- pooled particle/light playback with optional server replication.

	Purpose:
		Play visual effects (ParticleEmitters, Lights, attachments, models) by name without
		cloning fresh assets every time. Effects live in `ReplicatedStorage.Assets.VFX` and are
		pooled so repeated spawns are cheap. Can be fired locally on one client or replicated
		to some/all clients through the shared Network events.

	When to use:
		- Gunshot sparks, hit flashes, ability casts, environmental one-shots -- anything you
		  want cloned out of a template and emitted at a position.
		- Anywhere you'd normally `Clone()` a particle attachment, `:Emit()`, then debris it --
		  this handles pooling + lifetime + replication for you.

	Example:
		local VFX = Framework.Services.VFX
		VFX.newVFX({
			VFXName = "Explosion",    -- must match a child of ReplicatedStorage.Assets.VFX
			CFrame = hitCFrame,
			Replicate = true,         -- server->all clients (if called from client, routes through server)
			-- Recipients = { player1, player2 }, -- optional whitelist
			Destroy = true,           -- return to pool after longest particle's Lifetime.Max
			-- Looped = true, DestroyAfter = 3, -- looping variant
		})

	Gotchas:
		- Both client and server call `:Init()`. Emission (particles actually firing) always
		  happens on clients -- the server's job is purely to fan out the replication event.
		- `ReplicatedStorage.Assets.VFX` must exist at load time. If it's missing, the
		  `WaitForChild` on line 17 yields forever and the framework never finishes loading.
		- Custom effect modules under `script.CustomEffects` are only required on the client.
		  A custom returning `false` suppresses the default emit pass; `nil`/no return means
		  "go ahead and emit as usual" (see the `emitAnyways` logic).
		- The `Configuration` child on a VFX template provides default values that get
		  overridden by whatever you pass in `data` -- handy for per-asset tuning.
]]

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

-- wVFX: visible parent for live effects that don't have a caller-supplied Parent.
-- Only the server creates the folder; clients wait for it to replicate in.
local wVFX = workspace:FindFirstChild("VFX") or
	(not isClient and Instance.new("Folder", workspace))
	or workspace:WaitForChild("VFX")
wVFX.Name = "VFX"
-- rVFX: hidden "parked" parent for pooled instances that aren't currently playing.
-- Sitting in ReplicatedStorage keeps them out of workspace queries but still alive.
local rVFX = rs:FindFirstChild("VFXStorage") or
	(not isClient and Instance.new("Folder", rs))
	or rs:WaitForChild("VFXStorage")
rVFX.Name = "VFXStorage"

---<>--- Helpers ---<>---

-- Pulls an instance out of its named pool. Silently returns nil if the name
-- doesn't match a registered asset -- callers check for that below.
local function getVFX(particleName : string) : (Instance, typeof(vfxPools[1]))

	local foundPool = vfxPools[particleName]
	if not foundPool then return end
	local obj = foundPool:Get()

	return obj, foundPool
end

-- Fan-out used only on the server. `Recipients` lets you scope replication to
-- specific players (e.g. teammates only); otherwise everyone sees it.
local function sendToClients(action : string, data : {Recipients : {Player}})
	if data.Recipients then
		for _, plr in data.Recipients do
			VFXGlobalEvent:FireClient(plr, action, data)
		end
	else
		VFXGlobalEvent:FireAllClients(action, data)
	end
end

-- Merges the VFX template's `Configuration` ValueBase children with the caller's
-- data table. Template values are baseline defaults; caller data wins on conflict.
-- This lets artists tune per-asset defaults without touching code.
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

			-- Accept either a pre-built CFrame or a bare Position; fall back to origin
			-- so we never crash on a config missing both.
			local cf = config.CFrame or (config.Position and CFrame.new(config.Position)) or CFrame.new(0,0,0)
			if new:IsA("Model") then
				new:PivotTo(cf)
			elseif new:IsA("BasePart") then
				new.CFrame = cf
			elseif new:IsA("Attachment") then
				-- Attachments have two CFrame slots: one relative to parent, one in world
				-- space. UseLocalAttachmentCF = true when you want the effect to ride
				-- along with the parent (e.g. bolted to a weapon); default is worldspace.
				if data.UseLocalAttachmentCF then
					new.CFrame = cf
				else
					new.WorldCFrame = cf
				end
			end

			new.Parent = config.Parent or wVFX

			-- If there's a matching module under CustomEffects, let it run first.
			-- Custom modules can do bespoke work (tweens, sounds, etc.) and optionally
			-- suppress the standard emit pass by returning false.
			local custom = loadedEffects[VFXName] :: (Instance, {})->()
			local customResult = custom and custom(new, config)

			-- Default is "yes emit"; a custom explicitly returning false turns it off.
			-- nil/no return from a custom still emits so authors don't have to return true.
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
			-- Bounce through the server so every (or scoped) client sees it.
			VFXGlobalEvent:FireServer("New", data)
		else
			-- Local-only effect: keeps traffic off the wire for stuff only we need to see.
			VFXLocalEvent:Fire("New", data)
		end
	else--                                          //Server Side
		-- Server code calling newVFX directly -- broadcast straight to clients.
		-- (The server never plays particles itself; clients do the visual work.)
		sendToClients("New", data)
	end

end

---<>--- Initialization ---<>----

function VFX:Init()

	local Shared = require(script.Parent.Parent.Parent) :: any
	VFXGlobalEvent = Shared.GlobalEvents.VFX
	VFXLocalEvent = Shared.LocalEvents.VFX

	for _, vfx in vfxAssets:GetChildren() do

		-- Stash each emitter/light's authored `Enabled` value as an attribute so the
		-- pool's reset callback can restore the artist's intent on return. Without this
		-- we'd have no way to tell "was this always-on ambient" from "fires on demand"
		-- after we've toggled it off to stop emission.
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
			-- Reset callback: runs when an instance is returned to the pool. We park
			-- it in rVFX (hidden storage), restore each emitter/light to its authored
			-- Enabled state (see DefaultEnabled attribute above), and `:Clear()` any
			-- still-alive particles so the next caller doesn't see leftovers.
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

		-- Clients listen for both the networked path (server->client) and the local
		-- path (same-client fire). Same handler either way -- onEvent doesn't care
		-- where the data originated, it just spawns the effect.
		VFXGlobalEvent:Connect(onEvent)
		VFXLocalEvent:Connect(onEvent)

		-- Custom effect modules are keyed by name -- matching a VFX asset name lets
		-- that module piggy-back on the spawn. Server doesn't need these since it
		-- never actually plays effects.
		for _, effect in customEffects:GetChildren() do
			if effect:IsA("ModuleScript") then
				local func = require(effect)
				loadedEffects[effect.Name] = func
			end
		end

	else--                              //Server Side
		-- Server's only job: relay client-requested replication to the right audience.
		-- It never runs onEvent itself since it wouldn't do anything visible.
		VFXGlobalEvent:Connect(function(plr : Player, action : string, data)
			sendToClients(action, data)
		end)
	end

end

return VFX