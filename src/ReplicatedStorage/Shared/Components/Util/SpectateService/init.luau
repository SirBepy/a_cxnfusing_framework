--[[
	SpectateService (client)
	------------------------
	Purpose:
		Client-side helper for "watch another player / model / part". Swaps
		the CameraSubject to whatever you point at and, optionally, locks
		into first person or a custom scripted camera via CameraManager.

	When to use:
		Death-cam / spectate UI, focusing the camera on a cutscene actor,
		debug-style "follow this NPC". Call :Watch(target) to start,
		:StopWatching() to return to your own character.

	Example:
		local Spectate = require(Shared.Util.SpectateService)
		Spectate:Init()
		Spectate:Watch(otherPlayer, { SpectateType = "LockFirstPerson" })

	Gotchas:
		- Client-only. Requiring on the server returns a stub (`true`).
		- If the current watched player leaves or our own character respawns,
		  Init hooks auto-fall back to watching ourselves.
		- UseNativeFirstPerson = true uses Roblox's built-in LockFirstPerson
		  camera mode; set it false to force the scripted CameraManager path.
]]

local SpectateClient = {}

---<>--- Variables ---<>---

-- Server-side require: return a truthy stub so shared imports don't blow up.
if not game:GetService("RunService"):IsClient() then return true :: main end

local cam = workspace.CurrentCamera
local ourPlr = game:GetService("Players").LocalPlayer

local camManager = require(script:WaitForChild("CameraManager"))

local curWatching = ourPlr
local curCam : typeof(camManager)

-- Remember the user's original CameraMode so StopWatching can restore it
-- after a temporary LockFirstPerson spectate session.
local prevCamMode = ourPlr.CameraMode

local defaultOptions = {
	SpectateType = "Custom", -- If LockFirstPerson will be in first person, else just the default Custom third person camera.
	UseNativeFirstPerson = true, -- Use plr.CameraMode = Enum.CameraMode.LockFirstPerson instead of the camManager.new()
	ReturnToDefaultOnSelf = true, -- If set to false will use specate options on your own player camera when using the :Watch(LocalPlayer)
}

type main = typeof(SpectateClient)

---<>--- Helpers ---<>---

local function getChr(from : Player | Model | BasePart) : (Model? | BasePart?, boolean?)
	if not from then return end

	if from:IsA("Player") then
		return from.Character, true
	elseif from:IsA("Model") then
		return from, true
	elseif from:IsA("BasePart") then
		return from, false
	end

end

local function getHum(from : Model) : Humanoid?
	if not from then return end
	return from:FindFirstChildOfClass("Humanoid")
end

local function getOptions(override : {})
	if not override then return defaultOptions end
	local new = table.clone(defaultOptions)
	for i, v in new do
		if override[i] ~= nil then
			new[i] = override[i]
		end
	end
	return new
end

---<>--- Main Functions ---<>---

function SpectateClient:SetDefaultOptions(options : {
	SpectateType : "Custom" | "LockFirstPerson",
	UseNativeFirstPerson : boolean,
	ReturnToDefaultOnSelf : boolean,
	})
	local filled = getOptions(options)
	defaultOptions = filled
end

function SpectateClient:Watch(toWatch : Player | Model | BasePart, options : {
	SpectateType : "Custom" | "LockFirstPerson",
	UseNativeFirstPerson : boolean,
	ReturnToDefaultOnSelf : boolean,
	})
	if not toWatch then SpectateClient:StopWatching() return end
	-- Always tear down any existing scripted camera before starting a new one,
	-- otherwise they'd fight each other on RenderStepped.
	if curCam then curCam:Destroy() curCam = nil camManager.close() end

	options = getOptions(options)

	local obj, isModel = getChr(toWatch)
	if not obj then return end
	local hum = isModel and getHum(obj)

	local isPlr = toWatch:IsA("Player")

	if obj and hum then

		cam.CameraSubject = hum
		curWatching = isPlr and toWatch or obj

	elseif obj then
		cam.CameraSubject = obj
		curWatching = obj
	end

	-- Only apply the spectate-camera mode when we're watching *someone else*,
	-- unless the caller explicitly wants it applied to self too.
	if not options.ReturnToDefaultOnSelf or toWatch ~= ourPlr then
		if options.SpectateType == "LockFirstPerson" then

			-- Native path: just flip LocalPlayer.CameraMode. Only stash the
			-- previous mode if it wasn't already LockFirstPerson, so repeated
			-- Watch calls don't clobber our restore target.
			if isPlr and options.UseNativeFirstPerson then
				if ourPlr.CameraMode ~= Enum.CameraMode.LockFirstPerson then
					prevCamMode = ourPlr.CameraMode
				end
				ourPlr.CameraMode = Enum.CameraMode.LockFirstPerson
				return
			else
				ourPlr.CameraMode = Enum.CameraMode.Classic
			end

			-- Scripted path: mount CameraManager on Head if we have one (gives a
			-- face-level view), fall back to the model's PrimaryPart, or the BasePart itself.
			local prim = obj:IsA("Model") and(obj:FindFirstChild("Head") or obj.PrimaryPart) or obj:IsA("BasePart") and obj
			if not prim then return end

			curCam = camManager.new(prim, {CanLookAroundX = false, CanLookAroundY = false})
			curCam:Open()

		end
	end

end

function SpectateClient:StopWatching()
	ourPlr.CameraMode = prevCamMode
	if curCam then curCam:Destroy() curCam = nil end
	SpectateClient:Watch(ourPlr, {ReturnToDefaultOnSelf = true})
end

function SpectateClient:GetWatched() : Player | Model | BasePart
	return curWatching
end

function SpectateClient:Init()

	ourPlr.CharacterAdded:Connect(function(newChr)
		if curWatching == ourPlr then
			SpectateClient:StopWatching()
		end
	end)
	
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		if curWatching == player then
			SpectateClient:StopWatching()
		end
	end)

end

return SpectateClient :: main