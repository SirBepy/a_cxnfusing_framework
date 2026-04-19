--[[
	Purpose:
		Stamps a textured decal onto whatever a raycast hit, aligned to the
		surface normal. Auto-cleans after Lifetime + optional FadeTime.

	When to use:
		Bullet holes, blood splats, scorch marks, paintball hits, footprints.
		Anything where you already have a RaycastResult and want to leave a
		short-lived visual mark.

	Example:
		local result = workspace:Raycast(origin, direction * 500)
		DecalProjector:Project(result, {
			Texture = "rbxassetid://12345",
			Size = Vector2.new(1.5, 1.5),
			Lifetime = 5,
			FadeTime = 1,
		})

	Gotchas:
		- Hosts decals on an anchored Part inside a workspace.Debris folder.
		  Decal parts are CanCollide/CanTouch/CanQuery = false so they don't
		  interfere with gameplay raycasts.
		- Offsets the part by 0.05 studs along the normal to avoid z-fighting
		  with the hit surface.
		- Silently no-ops if result or Texture is missing.
]]

local DecalProjector = {}

---<>--- Variables ---<>---

local table = require(script.Parent:WaitForChild("ExtendedLibraries")).table
local fastTween = require(script.Parent.Parent:WaitForChild("Functions")).FastTween

local debrisFolder = workspace:FindFirstChild("Debris") or Instance.new("Folder", workspace)
debrisFolder.Name = "Debris"

---<>--- Helper Functions ---<>---

local function createPart(size : Vector2)
	local part = Instance.new("Part")
	part.Name = "ImpactDecal"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(size.X, size.Y, 0.1)
	part.Parent = debrisFolder
	return part
end

---<>--- Main Functions ---<>---

function DecalProjector:Project(result: RaycastResult, config: {
	Texture: string,

	Size: Vector2,
	Color: Color3,

	Lifetime: number,
	FadeTime: number,
	})
	if not result then return end

	local set = table.merge({
		Size = Vector2.new(2, 2),
		Color = Color3.new(1, 1, 1),

		Lifetime = 3,
		FadeTime = 1,
	}, config)
	if not set.Texture then return end

	local part = createPart(set.Size)

	local surfacePos = result.Position
	local surfaceNormal = result.Normal

	-- Nudge 0.05 studs along the normal so the decal doesn't z-fight with the
	-- underlying surface. lookAt aims the part's -Z at the surface, which is
	-- the face Decals render on when Decal.Face = Front (the default).
	part.CFrame = CFrame.lookAt(surfacePos + (surfaceNormal * 0.05), surfacePos + surfaceNormal)

	local decal = Instance.new("Decal", part)
	decal.Texture = set.Texture
	decal.Color3 = set.Color

	task.delay(set.Lifetime, function()
		if set.FadeTime > 0 then
			fastTween(
				decal,
				{set.FadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut},
				{Transparency = 1}
			)
			task.wait(set.FadeTime)
		end
		part:Destroy()
	end)

	return part
end

return DecalProjector