local module = {}

local animators = {}
local anims = {}

function module:SetUp(chr : Model)
	if not chr then return end
	local Animator = chr:FindFirstChildWhichIsA("Animator", true)
	animators[chr] = Animator
end

function module:ClearInfo(chr : Model)
	if animators[chr] then
		animators[chr] = nil
	end
end

function module:LoadAnims(chr : Model, animFolder : Folder)
	if not animators[chr] then return end
	for i, anim in ipairs(animFolder:GetChildren()) do
		if anim:IsA("Animation") then
			local track = animators[chr]:LoadAnimation(anim)
			anims[anim.Name] = track
		end
	end
	return anims
end

function module:StopAllAnims(chr : Model)
	if not animators[chr] then return end
	for i, anim in ipairs(animators[chr]:GetPlayingAnimationTracks()) do
		anim:Stop()
	end
end

function module:PlayAnim(chr : Model, animName : string, anim : Animation, fadeTime : number)
	if not animators[chr] then return end
	local track : AnimationTrack = animName and anims[animName] or (anim and animators[chr]:LoadAnimation(anim))
	if track then
		track:Play(fadeTime or 0.1)
	end
	return track
end

return module