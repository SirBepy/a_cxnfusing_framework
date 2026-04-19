--[[

---<>--- DOCUMENTATION ---<>---

--------------------------------------------------------------------------------------------------

Usage:

	To use this in a game, simply require the module:
	
		local CameraManager = require(...)
	
	Then to add cameras to it do something along the lines of:
	
		local camPart : BasePart | Attachment = workspace.CameraPart
		local newCam = CameraManager.new(camPart) -- supports second argument, a Config table.
	
	Now you have access to the following methods:
	
		- newCam:Open() : Opens the camera, if there was already a camera open before, it will override.
		- newCam:Destroy() : Destroys the metatable, so no methods will work after this

	Additionally, the module itself has a close method:
	
		CameraManager.close() -- this method doesn't destroy any cameras, it just closes if there is one open.
		-- Also, this is a method of the module itself, not of the 'newCam' metatable.
	
	That's it!
	
--------------------------------------------------------------------------------------------------

Config:

	The following settings are available:
	
		- FOV : number : Field of view for the camera, if left blank, it won't change the players FOV.

		- CanLookAroundX : boolean : If the camera can look around left and right.
		- CanLookAroundY : boolean : If the camera can look around up and down.
	
		- RotLerpAmount : number : How fast the camera rotates (1 is instant)

		- LookXDivider : number : How much it can rotate left and right.
		- LookYDivider : number : How much it can rotate up and down.
	
--------------------------------------------------------------------------------------------------
	
Other Info:

	If you have a moving part or attachment,
	the camera will snap to it's position, and keep smooth rotation.
	
	
--------------------------------------------------------------------------------------------------
	
Example Usage:

	local CameraManager = require(...)
	local cams = {}
	
	task.wait(2) -- in case game not loaded.
	
	for _, camPart in workspace.Cameras:GetChildren() do
		local new = CameraManager.new(camPart) -- new camera
		table.insert(cams, new)
	end
	
	local i = 0
	while wait(3) do
	
		i += 1
		if i > #cams then
			i = 1
		end
		
		local cur = cams[i]
		cur:Open() -- opens the 'cur' camera.
		
	end
	
--------------------------------------------------------------------------------------------------
	
Credits:


					made by
                                                   
                    ▄▄                             
                   ██              ▀▀              
▄████ ██ ██ ████▄ ▀██▀ ██ ██ ▄█▀▀▀ ██  ▄███▄ ████▄ 
██     ███  ██ ██  ██  ██ ██ ▀███▄ ██  ██ ██ ██ ██ 
▀████ ██ ██ ██ ██  ██  ▀██▀█ ▄▄▄█▀ ██▄ ▀███▀ ██ ██ 
                                                   
                                                   
]]

--[[
	CameraManager (short summary — full docs above)
	-----------------------------------------------
	Purpose:
		Scriptable-camera wrapper for fixed camera parts/attachments. Point
		at a Part/Attachment, call :Open(), and the player's camera snaps to
		it with mouse-driven look-around and smooth rotation. SpectateService
		uses this for its non-native first-person path.

	When to use:
		Cinematic cameras, security-cam style viewpoints, first-person rigs
		attached to a body part. When native Roblox camera modes aren't
		flexible enough.

	Example:
		local CameraManager = require(...)
		local cam = CameraManager.new(workspace.CameraPart, { FOV = 80 })
		cam:Open()

	Gotchas:
		- Only one camera is "open" at a time; :Open() on a new one
		  overrides the previous.
		- :Destroy() nils every field on self, so any held reference becomes
		  useless — don't keep using it after destroying.
		- Attachment targets use WorldCFrame; BaseParts use CFrame.
]]

local Manager = {}
Manager.__index = Manager

-- CurrentCamera is cached at module load. If a script swaps it later this
-- module won't follow; Roblox almost never does that, so fine in practice.
local cc = workspace.CurrentCamera

local plr = game.Players.LocalPlayer
local mouse = plr:GetMouse()

-- Global sensitivity multiplier applied on top of per-camera LookXDivider/YDivider.
-- Small value = small look-around angles (this is a peek-style camera, not full FPS).
local camRotMult = 0.05

local curOpen = nil

type Config = {

	FOV : number,

	CanLookAroundX : boolean,
	CanLookAroundY : boolean,
	
	RotLerpAmount : number,

	LookXDivider : number,
	LookYDivider : number,

}

local defaultConfig = {

	CanLookAroundX = true,
	CanLookAroundY = true,
	
	RotLerpAmount = 0.05,

	LookXDivider = 1,
	LookYDivider = 1,

}

local function fillConfig(toFill : Config)
	local n = {}
	for i, v in pairs(toFill) do
		n[i] = v
	end
	for i, v in pairs(defaultConfig) do
		if n[i] == nil then
			n[i] = v
		end
	end
	return n
end

local function getCamRotation(config : Config)

	-- Offset from screen center → rotation amount. Negated so the camera
	-- looks toward the cursor, not away from it.
	local rotX = -(mouse.Y - mouse.ViewSizeY / 2)/config.LookYDivider
	local rotY = -(mouse.X - mouse.ViewSizeX / 2)/config.LookXDivider
	
	if not config.CanLookAroundY then
		rotX = 0
	end
	if not config.CanLookAroundX then
		rotY = 0
	end

	rotX*=camRotMult
	rotY*=camRotMult

	return CFrame.Angles(math.rad(rotX), math.rad(rotY), 0)

end

--Creates a new camera metatable.
function Manager.new(CamPart : Part | Attachment, Config : Config)

	local self = setmetatable({}, Manager)

	Config = Config or defaultConfig
	Config = fillConfig(Config)

	self.Part = CamPart
	self.Config = Config

	return self

end

--Destroys the camera metatable, no methods will work once called.
function Manager:Destroy()

	for index, val in self do
		self[index] = nil
	end

	setmetatable(self, nil)
	
	if curOpen == self then
		Manager.close()
	end

end

--Opens the camera, if there was already a camera open before, it will override.
function Manager:Open()

	local camPart : BasePart | Attachment = self.Part
	local config : Config = self.Config

	cc.CameraType = Enum.CameraType.Scriptable
	if camPart:IsA("Attachment") then
		cc.CFrame = camPart.WorldCFrame
	else
		cc.CFrame = camPart.CFrame
	end
	if config.FOV then
		cc.FieldOfView = config.FOV
	end

	curOpen = self

end

--Closes any open cameras.
function Manager.close()

	curOpen = nil

	cc.CameraType = Enum.CameraType.Custom

end

game["Run Service"].RenderStepped:Connect(function()
	if curOpen then

		local camPart : BasePart | Attachment = curOpen.Part
		local config : Config = curOpen.Config

		-- Target CFrame = part's current CFrame rotated by mouse look.
		local cf = camPart:IsA("Attachment") and camPart.WorldCFrame or camPart.CFrame
		cf *= getCamRotation(config)

		-- Snap the position instantly (so moving cameras don't lag behind)
		-- but smooth-lerp the rotation toward the target.
		cc.CFrame = CFrame.new(cf.Position)*cc.CFrame.Rotation
		cc.CFrame = cc.CFrame:Lerp(cf,config.RotLerpAmount)

	end
end)

return Manager