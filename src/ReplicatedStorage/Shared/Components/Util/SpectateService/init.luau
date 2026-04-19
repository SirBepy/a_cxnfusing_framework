local SpectateClient = {}

---<>--- Variables ---<>---

if not game:GetService("RunService"):IsClient() then return true :: main end

local cam = workspace.CurrentCamera
local ourPlr = game:GetService("Players").LocalPlayer

local camManager = require(script:WaitForChild("CameraManager"))

local curWatching = ourPlr
local curCam : typeof(camManager)

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

	if not options.ReturnToDefaultOnSelf or toWatch ~= ourPlr then
		if options.SpectateType == "LockFirstPerson" then

			if isPlr and options.UseNativeFirstPerson then
				if ourPlr.CameraMode ~= Enum.CameraMode.LockFirstPerson then
					prevCamMode = ourPlr.CameraMode
				end
				ourPlr.CameraMode = Enum.CameraMode.LockFirstPerson
				return
			else
				ourPlr.CameraMode = Enum.CameraMode.Classic
			end

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