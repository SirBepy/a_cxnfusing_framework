local Emitter = {}

function Emitter:Emit(particle : ParticleEmitter) : number
	if not particle or not particle:IsA("ParticleEmitter") then return end

	local delayTime = particle:GetAttribute("Delay") or 0
	local emitCount = particle:GetAttribute("EmitCount") or 1

	if delayTime > 0 then
		task.delay(delayTime,function()
			particle:Emit(emitCount)
		end)
	else
		particle:Emit(emitCount)
	end

	local length = delayTime+particle.Lifetime.Max

	return length
end

function Emitter:LoopEmit(particle : ParticleEmitter) : number
	if not particle or not particle:IsA("ParticleEmitter") then return end

	local delayTime = particle:GetAttribute("Delay") or 0

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
	local toEmit = {obj, table.unpack(obj:GetDescendants())}

	for _, desc in toEmit do
		local length = Emitter:Emit(desc)
		if not length then continue end
		if length > longest then
			longest = length
		end
	end

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

	local destroyed = false

	local function destroy(instant : boolean)
		if destroyed then return end
		destroyed = true

		if instant then pool:Return(obj) return end

		pool:Return(obj)

	end

	if destroyAfter then
		task.delay(destroyAfter, destroy)
	end

	return destroy, longest
end

return Emitter