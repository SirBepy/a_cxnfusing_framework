--[[
	Purpose:
		Thin wrapper over SoundService for playing one-shot SFX by name or by
		category. Clones the source Sound each call so overlapping plays don't
		cut each other off, and auto-Debris's the clone once it finishes.

	When to use:
		Any non-looping gameplay SFX: gunshots, UI clicks, footsteps (one-shot
		variant), hit impacts. Use :PlayByCategory when you want a random variant
		from a pool (e.g. "Footstep_Grass/*").

	Example:
		SFXHandler:Play("Gunshot_Pistol", gun.Handle, { Volume = 0.8, RandomPitch = true })
		SFXHandler:PlayByCategory("Footstep_Grass", rootPart)

	Gotchas:
		- Expects ReplicatedStorage.Assets.SFX and a Categories sub-folder. Will
		  yield forever on require if those don't exist.
		- :Play does a linear GetDescendants search by name each call. Fine for
		  small libraries, O(n) otherwise.
		- Clone lifetime = TimeLength + 1 via Debris; if you need to stop early,
		  capture the return and :Stop/:Destroy yourself.
]]

local rs = game:GetService("ReplicatedStorage")
local framework = script.Parent.Parent.Parent

local sfx = rs:WaitForChild("Assets"):WaitForChild("SFX")
local categories = sfx:WaitForChild("Categories")

local SoundService = {}

type props = {Volume : number, Speed : number, Pitch : {number} | number, SoundGroup : string, RollOffDist : number, RandomPitch : boolean}

-- Attaches a PitchShiftSoundEffect with a randomized octave in the given range.
-- Range is expressed as integers meaning "percent of 1.0 octave" (so 90..110
-- becomes 0.9..1.1 Octave). Keeps callers from doing the math every time.
local function pitchShift(s : Sound, override : {number} | number)
	local shift = Instance.new("PitchShiftSoundEffect",s)
	local range = {90, 110}
	if type(override) == "number" then
		range[1] = override
		range[2] = override
	elseif type(override) == "table" then	
		range[1] = override[1] or 90
		range[2] = override[2] or 110
	end
	shift.Octave = math.random(range[1],range[2])/100
	return shift
end

-- Plays a sound by name
function SoundService:Play(obj: string | Sound, parent: Instance?, properties : props)
	
	local sound : Sound

	if typeof(obj) == "string" then
		for _, s in ipairs(sfx:GetDescendants()) do
			if s:IsA("Sound") and s.Name == obj then
				sound = s
				break
			end
		end
	else
		sound = obj
	end

	if not sound then return end

	local p : props = properties or {}

	-- Clone so multiple overlapping plays of the same sound don't stomp each
	-- other's playback position. Original asset stays untouched.
	local clone = sound:Clone()

	clone.Parent = parent or game:GetService("SoundService")

	clone.Volume = p.Volume or 1
	clone.PlaybackSpeed = p.Speed or 1
	clone.RollOffMaxDistance = p.RollOffDist or 10000
	
	clone.SoundGroup = p.SoundGroup or ""
	
	if p.Pitch then
		local new = pitchShift(clone, p.Pitch)
	elseif p.RandomPitch then
		pitchShift(clone)
	end

	clone:Play()

	-- +1 second buffer past TimeLength so Debris doesn't yank the sound mid-tail
	-- (reverb, pitch-shifted stretches, etc.).
	game:GetService("Debris"):AddItem(clone, clone.TimeLength + 1)

	return clone

end

function SoundService:PlayByCategory(name : string, parent : Instance?, properties : props?)
	local sound : Sound
	for _, c in ipairs(categories:GetDescendants()) do
		if c:IsA("Folder") and c.Name == name then
			sound = c:GetChildren()[math.random(1,#c:GetChildren())]
			break
		end
	end
	return SoundService:Play(sound, parent, properties)
end

return SoundService