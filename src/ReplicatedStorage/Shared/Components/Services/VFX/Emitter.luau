--[[
	Emitter -- internal helper for the VFX service.

	Purpose:
		Drive ParticleEmitter playback with per-emitter `Delay` and `EmitCount` attributes,
		and return the total time a given pass will take so callers can schedule pool
		returns. Two modes: one-shot burst (`Emit`/`EmitAll`) and enabled-loop
		(`LoopEmit`/`LoopEmitAll`).

	When to use:
		You probably shouldn't require this directly -- `Services.VFX` wraps it. If you're
		writing a custom effect module under `VFX/CustomEffects`, the VFX service already
		calls EmitAll/LoopEmitAll for you after your module runs.

	Example:
		-- inside VFX.onEvent:
		emitter:EmitAll(clonedVFX, true, pool)       -- one-shot, auto-return when done
		emitter:LoopEmitAll(clonedVFX, 3, pool)      -- loop for 3 seconds then return

	Gotchas:
		- Client-only in practice. The VFX service never invokes Emitter on the server,
		  so there's no server guard here -- if you call these yourself from the server
		  you'll toggle particle state on the server replica and nothing will be visible.
		- Emitters opt into a staggered burst by setting `Delay` / `EmitCount` attributes
		  on the ParticleEmitter itself. No attributes = instant single emit.
		- `EmitAll` waits `longest` seconds before returning the object to the pool. That
		  yield happens on the calling thread -- VFX.onEvent spawns it implicitly via the
		  event connection, so bursts don't block each other, but keep in mind if you call
		  it directly.
		- `LoopEmit` uses ParticleEmitter.Enabled = true and never sets it false itself --
		  the pool's reset callback is what stops looping emitters (see VFX init.luau).
]]

local Emitter = {}

function Emitter:Emit(particle : ParticleEmitter) : number
	if not particle or not particle:IsA("ParticleEmitter") then return end

	-- Attribute-driven: artists can tune per-emitter timing in Studio without code.
	local delayTime = particle:GetAttribute("Delay") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 1

	if delayTime > 0 then
		task.delay(delayTime,function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end

	-- "Length" = when the last particle from this burst will have decayed. Callers
	-- add their own safety margin via destroy/DestroyAfter; we just report max lifetime.
	local length = delayTime+particle.Lifetime.Max

	return length
end

function Emitter:LoopEmit(particle : ParticleEmitter) : number
	if not particle or not particle:IsA("ParticleEmitter") then return end

	local delayTime = particle:GetAttribute("Delay") or 0

	-- Looped variant just flips Enabled; the pool reset callback turns it back off.
	if delayTime > 0 then
		task.delay(delayTime,function()
			particle.Enabled = true
		end)
	else
		particle.Enabled = true
	end

	local length = delayTime+particle.Lifetime.Max
	local destroyed = false

	return length
end

function Emitter:EmitAll(obj : Instance, destroy : boolean, pool) : number

	local longest = 0
	-- Include `obj` itself in case it's a ParticleEmitter directly (not just a
	-- container with emitters inside). :Emit skips anything that isn't an emitter.
	local toEmit = {obj, table.unpack(obj:GetDescendants())}

	for _, desc in toEmit do
		local length = Emitter:Emit(desc)
		if not length then continue end
		if length > longest then
			longest = length
		end
	end

	-- `destroy` defaults to true (nil check) -- pass false explicitly to keep the
	-- object alive (e.g. you're managing its lifetime yourself).
	if destroy ~= false then
		task.wait(longest)
		pool:Return(obj)
	end

	return longest
end

function Emitter:LoopEmitAll(obj : Instance, destroyAfter : number, pool) : (()->(), number)

	local longest = 0
	local toEmit = {obj, table.unpack(obj:GetDescendants())}

	for _, desc in toEmit do
		local length = Emitter:LoopEmit(desc)
		if not length then return end
		if length > longest then
			longest = length
		end
	end

	-- `destroyed` latch: the returned destroy() can be called manually and also by
	-- the task.delay below -- whichever fires first wins, subsequent calls no-op.
	local destroyed = false

	local function destroy(instant : boolean)
		if destroyed then return end
		destroyed = true

		-- `instant` is currently a no-op branch (both paths just Return) but kept
		-- around so future code can e.g. skip a fadeout when instant is true.
		if instant then pool:Return(obj) return end

		pool:Return(obj)

	end

	-- Optional auto-stop. Without destroyAfter, caller is responsible for calling
	-- the returned destroy() function when the loop should end.
	if destroyAfter then
		task.delay(destroyAfter, destroy)
	end

	return destroy, longest
end

return Emitter