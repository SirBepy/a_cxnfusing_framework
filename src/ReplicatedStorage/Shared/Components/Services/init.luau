return {

	ReplicatedFirst = game:GetService("ReplicatedFirst"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	ServerStorage = game:GetService("ServerStorage"),

	ServerScriptService = game:GetService("ServerScriptService"),

	Players = game:GetService("Players"),

	UserInputService = game:GetService("UserInputService"),
	RunService = game:GetService("RunService"),

	TweenService = game:GetService("TweenService"),

	CollectionService = game:GetService("CollectionService"),
	ContentProvider = game:GetService("ContentProvider"),
	
	StarterGui = game:GetService("StarterGui"),
	StarterPlayer = game:GetService("StarterPlayer"),
	StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"),
	StarterCharacterScripts = game:GetService("StarterPlayer"):WaitForChild("StarterCharacterScripts"),
	
	Lighting = game:GetService("Lighting"),
	SoundService = game:GetService("SoundService"),
	
	--
	
	DataService = require(script:WaitForChild("DataService")),
	VFX = require(script:WaitForChild("VFX")),

}