-- Camera Shake Instance
-- Stephen Leitnick
-- February 26, 2018
--
-- VENDORED: Part of Sleitnick's RbxCameraShaker. Don't restyle.

--[[
	Purpose:
		Single shake "source" with its own magnitude, roughness, and fade curves.
		CameraShaker owns a list of these and sums their offsets per frame.

	When to use:
		Build directly via .new when you want one-off custom shakes. Usually you
		don't touch this file, you just grab one from CameraShakePresets or let
		CameraShaker:ShakeOnce/StartShake build it for you.

	Example:
		local inst = CameraShakeInstance.new(5, 10, 0, 1.5) -- magnitude, roughness, fadeIn, fadeOut
		camShake:Shake(inst)

	Gotchas:
		- `tick` is seeded randomly so two shakes don't produce identical noise.
		- Setting DeleteOnInactive = false lets you keep and re-trigger the same
		  instance without reallocating.
]]



local CameraShakeInstance = {}
CameraShakeInstance.__index = CameraShakeInstance

local V3 = Vector3.new
local NOISE = math.noise


CameraShakeInstance.CameraShakeState = {
	FadingIn = 0;
	FadingOut = 1;
	Sustained = 2;
	Inactive = 3;
}


function CameraShakeInstance.new(magnitude, roughness, fadeInTime, fadeOutTime)
	
	if (fadeInTime == nil) then fadeInTime = 0 end
	if (fadeOutTime == nil) then fadeOutTime = 0 end
	
	assert(type(magnitude) == "number", "Magnitude must be a number")
	assert(type(roughness) == "number", "Roughness must be a number")
	assert(type(fadeInTime) == "number", "FadeInTime must be a number")
	assert(type(fadeOutTime) == "number", "FadeOutTime must be a number")
	
	local self = setmetatable({
		Magnitude = magnitude;
		Roughness = roughness;
		PositionInfluence = V3();
		RotationInfluence = V3();
		DeleteOnInactive = true;
		roughMod = 1;
		magnMod = 1;
		fadeOutDuration = fadeOutTime;
		fadeInDuration = fadeInTime;
		sustain = (fadeInTime > 0);
		currentFadeTime = (fadeInTime > 0 and 0 or 1);
		tick = Random.new():NextNumber(-100, 100);
		_camShakeInstance = true;
	}, CameraShakeInstance)
	
	return self
	
end


function CameraShakeInstance:UpdateShake(dt)
	
	local _tick = self.tick
	local currentFadeTime = self.currentFadeTime
	
	local offset = V3(
		NOISE(_tick, 0) * 0.5,
		NOISE(0, _tick) * 0.5,
		NOISE(_tick, _tick) * 0.5
	)
	
	if (self.fadeInDuration > 0 and self.sustain) then
		if (currentFadeTime < 1) then
			currentFadeTime = currentFadeTime + (dt / self.fadeInDuration)
		elseif (self.fadeOutDuration > 0) then
			self.sustain = false
		end
	end
	
	if (not self.sustain) then
		currentFadeTime = currentFadeTime - (dt / self.fadeOutDuration)
	end
	
	if (self.sustain) then
		self.tick = _tick + (dt * self.Roughness * self.roughMod)
	else
		self.tick = _tick + (dt * self.Roughness * self.roughMod * currentFadeTime)
	end
	
	self.currentFadeTime = currentFadeTime
	
	return offset * self.Magnitude * self.magnMod * currentFadeTime
	
end


function CameraShakeInstance:StartFadeOut(fadeOutTime)
	if (fadeOutTime == 0) then
		self.currentFadeTime = 0
	end
	self.fadeOutDuration = fadeOutTime
	self.fadeInDuration = 0
	self.sustain = false
end


function CameraShakeInstance:StartFadeIn(fadeInTime)
	if (fadeInTime == 0) then
		self.currentFadeTime = 1
	end
	self.fadeInDuration = fadeInTime or self.fadeInDuration
	self.fadeOutDuration = 0
	self.sustain = true
end


function CameraShakeInstance:GetScaleRoughness()
	return self.roughMod
end


function CameraShakeInstance:SetScaleRoughness(v)
	self.roughMod = v
end


function CameraShakeInstance:GetScaleMagnitude()
	return self.magnMod
end


function CameraShakeInstance:SetScaleMagnitude(v)
	self.magnMod = v
end


function CameraShakeInstance:GetNormalizedFadeTime()
	return self.currentFadeTime
end


function CameraShakeInstance:IsShaking()
	return (self.currentFadeTime > 0 or self.sustain)
end


function CameraShakeInstance:IsFadingOut()
	return ((not self.sustain) and self.currentFadeTime > 0)
end


function CameraShakeInstance:IsFadingIn()
	return (self.currentFadeTime < 1 and self.sustain and self.fadeInDuration > 0)
end


function CameraShakeInstance:GetState()
	if (self:IsFadingIn()) then
		return CameraShakeInstance.CameraShakeState.FadingIn
	elseif (self:IsFadingOut()) then
		return CameraShakeInstance.CameraShakeState.FadingOut
	elseif (self:IsShaking()) then
		return CameraShakeInstance.CameraShakeState.Sustained
	else
		return CameraShakeInstance.CameraShakeState.Inactive
	end
end


return CameraShakeInstance