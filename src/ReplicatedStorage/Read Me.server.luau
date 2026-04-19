--[[


Made by                                        
                    ▄▄                             
                   ██              ▀▀              
▄████ ██ ██ ████▄ ▀██▀ ██ ██ ▄█▀▀▀ ██  ▄███▄ ████▄ 
██     ███  ██ ██  ██  ██ ██ ▀███▄ ██  ██ ██ ██ ██ 
▀████ ██ ██ ██ ██  ██  ▀██▀█ ▄▄▄█▀ ██▄ ▀███▀ ██ ██ 
                                                   
                                                   
cool text right??

anyways hi, this is my cool framework, lemme explain it to u!

---<>--- Paths and Features ---<>---

Soo the Framework consists of a couple parts
  - 'Framework' module
  - 'Shared' module
  - 'Assets' folder
 
and a few other folders like 'Modules', 'Services', and others depending on what u wanna add!

to use the framework in a Script/LocalScript, simply do:

local rs = game:GetService("ReplicatedStorage")
local Framework = require(rs:WaitForChild("Framework"))
Framework:WaitUntilLoaded()

FYI, the :WaitUntilLoaded() is fully optional, I just recommend it since it pauses scripts until
all the modules which need to be loaded are fully loaded and initialized.

to use the framework in a ModuleScript which is required (loaded) by the Framework, use Shared instead!

local rs = game:GetService("ReplicatedStorage")
local Shared = require(rs:WaitForChild("Shared"))

The main difference between the 2, is that Shared doesn't require any modules besides the utilities inside it.
This means there's no loading or dependencies, so you can use it anywhere.

Additionally, the Framework inherits all the data from the Shared module,
so the data will be the same no matter which one you require

Feature List:
  - Events
    + Global Events
    + Local Events
  - Services
  - Assets
  - Data (not used rlly)
  - Utilities
  - Functions
  - Info 
  - Config
  - Debris (game.Debris)
  
  - :IsServer()
  - :IsClient()
  - :IsStudio()
  - :Log()
  - :SafeCall()
  - :Preload()
  - :WaitUntilLoaded()
  
Feature Info:
  - Events:
    + Global Events: Basically RemoteEvents, with the addition of invoke methods.
    + Local Events: Signal module, nothing more.
  - Services: A list of commonly used Roblox services, as well as VFX and DataService.
  - Assets: Assets folder in ReplicatedStorage (recommend to simply do RS.Assets instead)
  - Data: Data folder in Shared, not used as of right now.
  - Utilities: List of all utilities contained inside the Framework.
  - Functions: List of all functions contained inside the Framework.
  - Info: List of all info contained inside the framework. (Info as in PlayerState, GameState, etc.)
  - Config: Game and Framework configuration.
  - Debris: game.Debris
  
  - :IsServer() - Returns whether it's called on server side.
  - :IsClient() - Returns whether it's called on client side.
  - :IsStudio() - Returns whether the game is running in studio.
  - :Log() - Output a message to the Output, using the Framework's Log module.
  - :SafeCall() - pcall()
  - :Preload() - Preload rbxassetid's or Instances using Roblox's ContentProvider service.
  - :WaitUntilLoaded() - Waits until the Framework is fully loaded.
  
---<>--- How to Add More ---<>---

But what if all this stuff isn't enough, and you wanna add more to it?

Events: 
  - Global Events
    + Open up the Shared module
    + Under 'GlobalEvents', add a name and set it to Network.newGlobal(name), like so:
    	NewEvent = Network.newGlobal("NewEvent"),
  - Local Events
    + Open up the Shared module
    + Under 'LocalEvents' add a name and set it to Network.newLocal(), like so:
    	NewEvent = Network.newLocal(),
    	
Utilties/Functions/Info/Services:
  - Find where you want to add your new module (Shared->Components->???)
  - Add the module and name it
  - Open up the parent ModuleScript
  - Add a name and set it to require your new module, like so:
  	ModuleName = require(script:WaitForChild("ModuleName"))
  
Modules (Not inside the regular Framework hierarchy):
  - Give your module the tag 'LoadModule'
  - Add any other optional tags/attributes
    + 'NonRecursive' tag, won't load any of the modules inside that module.
    + 'Type' attribute, if set to 'Client' or 'Server' will load only on the client or the server.
    
---<>--- Individual Docs ---<>---

		  W.I.P. sorry!

Utilities:

  - ActionBuffer:
   Description: 
    A simple module which allows you to record actions,
    and then check later on whether that action was recorded within a certain time window.
    Can be used for buffering attacks, jumps, abilities, and more.
   Methods:
    - :Record(actionName : string) - Saves/records an action.
    - :IsActive(actionName : string, customWindow : number) - Checks whether that action is recorded within the passed in time window.
    - :Clear(actionName : string) - Clears the action's recording.
  
  
  - Bezier:
   Description:
    A module which can be used to turn an array of points into
    a smooth bezier curve. Can be used for magic, attacks, effects, and more.
   Disclaimer:
    This module was written mostly with AI, since I can't do bezier math lol
   Methods:
    - .GetMagnetPath(t : number, points : {Vector3}) - Returns a position which is [t] (0-1) percent along the bezier curve.
      The returned point isn't guaranteed to go through the points passed in, only the first and last point are guaranteed.
    - .GetSmoothSpline(t : number, points : {Vector3}) - Returns a position which is [t] (0-1) percent along the bezier curve.
      The returned point is guaranteed to path through each point passed in.
   
   
  - CameraShaker:
   Description:
    A utility which can be used to shake the players camera,
    however I didn't make it so I can't write proper docs for it.
    Sorry!
    
    
  - ConnectToAdded: (function)
   Description:
    A function which allows you to connect a callback function to every child/descendant of an object.
    This also includes ones which are added later on (Instance.ChildAdded).
   Arguments:
    - obj : Instance - The object which will be used.
    - callback : (obj : Instance)->() - The callback function which will run for each child/descendant.
    - useDescendants : boolean - Whether it should run for each descendant or run for each child.
  
  
  - ConnectToTag: (function)
   Description:
    A function which allows you to connect a callback function to every instance with a certain tag.
    This also includes ones which are added later on (CollectionService:GetInstanceAddedSignal).
   Arguments:
    - tag : string - The tag which will be used.
    - callback : (obj : Instance)->() - The callback function which will run for each tagged instance.
  
]]