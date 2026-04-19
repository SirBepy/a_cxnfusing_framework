--[[
	Animator

	Purpose:
		Tiny wrapper around Roblox's Animator so dialogue commands (like
		`$pose:Greet$`) can load and play named animation tracks on an
		NPC without the caller wrangling AnimationTracks themselves.

	When to use:
		Call :SetUp(npc) once when the NPC spawns, :LoadAnims(npc, folder)
		to preload a folder of Animation instances by name, then
		:PlayAnim(npc, "Greet") from wherever (usually a CommandRun
		listener in your dialogue UI handler).

	Example:
		Animator:SetUp(npc)
		Animator:LoadAnims(npc, npc:WaitForChild("Anims"))
		controller.CommandRun:Connect(function(cmd, arg)
			if cmd == "pose" then
				Animator:StopAllAnims(npc)
				Animator:PlayAnim(npc, arg)
			end
		end)

	Gotchas:
		- The `anims` table is module-level (shared across ALL npcs). If
		  two NPCs have animations with the same Name, the second
		  :LoadAnims call overwrites the first. Fine for a single-NPC
		  demo, would need a per-model cache for production use.
		- Always call :ClearInfo(npc) when an NPC despawns to avoid
		  holding a dead reference to its Animator.
--]]

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