local ViewCheck = {}

---<>--- Variables ---<>---

local cam = workspace.CurrentCamera
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

---<>--- Helper Functions ---<>---

local function isOnScreen(target : Vector3)
	local _, onScreen = cam:WorldToViewportPoint(target)
	return onScreen
end

local function isBlocked(target : Vector3, ignoreList : {Instance}?)
	
	params.FilterDescendantsInstances = ignoreList or {}
	local origin = cam.CFrame.Position
	local ray = workspace:Raycast(origin, target - origin, params)

	return ray ~= nil
end

---<>--- Main Functions ---<>---

ViewCheck.IsOnScreen = isOnScreen
ViewCheck.IsBlocked = isBlocked

function ViewCheck.IsVisible(target: Vector3, ignoreList: {Instance}?)
	if not isOnScreen(target) then return false end
	return not isBlocked(target, ignoreList)
end

return ViewCheck