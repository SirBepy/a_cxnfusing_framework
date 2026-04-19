--[[
	Purpose:
		Tiny "can the camera actually see this world position?" helper. Combines
		an on-screen check (viewport) with a line-of-sight raycast from the
		camera to the target.

	When to use:
		Gate nameplates, quest markers, or VFX so they only run/show when
		visible. Skip expensive client logic for things off-screen or occluded.

	Example:
		if ViewCheck.IsVisible(npc.HumanoidRootPart.Position, { localPlayerCharacter }) then
			nameplate.Enabled = true
		end

	Gotchas:
		- Client-only (uses workspace.CurrentCamera).
		- The RaycastParams object is module-level and shared. Concurrent
		  callers mutate each other's FilterDescendantsInstances. Fine in
		  single-threaded Luau, but be aware if you ever switch to parallel.
		- IsOnScreen only checks viewport, not frustum-clip behind the camera
		  cleanly; WorldToViewportPoint's second return covers that.
]]

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