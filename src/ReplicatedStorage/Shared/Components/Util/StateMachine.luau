--[[
	StateMachine
	------------
	Purpose:
		Tiny finite state machine. Each state is a ModuleScript under
		`script.States` returning a table with optional CanEnter/OnEnter/
		OnExit/Update functions. Instances share the same state registry.

	When to use:
		- Player/enemy AI loops, UI screens with enter/exit hooks, game-mode
		  phases (Lobby -> Countdown -> Round -> Results).
		- Anywhere you'd otherwise juggle a pile of booleans for "what mode
		  are we in right now".

	Example:
		local sm = StateMachine.new("Idle")
		sm.OnEnter:Connect(function(newState, prev) print("entered", newState) end)
		sm:TryEnter("Attacking", targetPlayer)
		sm:Update(deltaTime)

	Gotchas:
		- The `states` registry is module-level, every StateMachine instance
		  shares it. If you need per-instance states, fork this.
		- `:Init()` requires a `States` child folder on this script to exist.
		  Call it once at boot before `.new`.
		- `TryEnter` silently no-ops on unknown states and on CanEnter = false.
		  Check `GetState()` if you need to confirm.
--]]

local StateMachine = {}
StateMachine.__index = StateMachine

---<>--- Variables ---<>---

type Signal = {
	Fire: (self: any, any) -> (),
	FireAllClients: (self: any, any) -> (),
	Connect: (self: any, callback: (any) -> ()) -> (),
}
type StateMachine = typeof(StateMachine)

local signal = require(script.Parent.Parent.Util.Signal)

-- Module-level registry shared by every StateMachine instance. Keyed by
-- state name (matches the child ModuleScript name under `script.States`).
local states = {}

---<>--- Main Functions ---<>---

function StateMachine.new(startingState : string, ...)

	local self = setmetatable({

		CurrentState = nil,
		PreviousState = nil,

		OnEnter = signal(),
		OnExit = signal(),
		OnUpdate = signal(),

	}, StateMachine)

	if startingState then
		self:TryEnter(startingState, ...)
	end

	return self :: StateMachine & {

		CurrentState : string?,
		PreviousState : string?,

		OnEnter : Signal,
		OnExit : Signal,
		OnUpdate : Signal,

	}
end

--Enters a new state if possible, if there's a current state already, it exits that one.
function StateMachine:TryEnter(newState : string, ...) : any
	if not newState or newState == self.CurrentState then return end

	local state = states[newState]
	if not state then return end

	-- CanEnter acts as a veto. Lets states gate their own entry conditions
	-- (e.g. "only enter Attack if cooldown ready") without the caller knowing.
	if state.CanEnter and not state.CanEnter(self.CurrentState, ...) then return end

	-- Exit the old state before entering the new one so OnExit always fires
	-- before OnEnter. `nil` switchTo avoids the recursive re-entry path.
	if self.CurrentState then
		self:Exit(nil, ...)
	end

	self.PreviousState = self.CurrentState
	self.CurrentState = newState
	
	local args
	if state.OnEnter then
		args = state.OnEnter(self.PreviousState, ...)
	end

	self.OnEnter:Fire(self.CurrentState, self.PreviousState, ...)
	
	return args
end

--Exits the current state, if 'switchTo' defined, enters that state and exits the current one.
function StateMachine:Exit(switchTo : string, ...) : any
	if not self.CurrentState then return end

	if switchTo then
		self:TryEnter(switchTo, ...)
		return
	end

	local state = states[self.CurrentState]
	if not state then return end
	
	local args
	if state.OnExit then
		args = state.OnExit(...)
	end

	self.PreviousState = self.CurrentState
	self.CurrentState = nil

	self.OnExit:Fire(self.PreviousState, ...)
	
	return args
end

--Calls .Update() on the current state (if available)
function StateMachine:Update(...) : any
	if not self.CurrentState then return end

	local state = states[self.CurrentState]
	if not state then return end

	if state.Update then
		self.OnUpdate:Fire(self.CurrentState, ...)
		return state.Update(...)
	end

end

--Returns the current state.
function StateMachine:GetState() : string?
	return self.CurrentState
end

--Returns the previous state.
function StateMachine:GetPreviousState() : string?
	return self.PreviousState
end

---<>--- Initialization ---<>---

function StateMachine:Init()

	for _, state in script:WaitForChild("States"):GetChildren() do
		if state:IsA("ModuleScript") then
			states[state.Name] = require(state)
		end
	end

end

return StateMachine :: StateMachine