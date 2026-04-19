--[[
	Actions/Test

	Purpose:
		Sample action module. Action modules live in Actions/ and are
		wired up by your own game code to respond to CommandRun signals
		fired by DialogueHandler (e.g. `$test$` in a dialogue line).

	When to use:
		Copy this file's shape when you add a real action. Each action
		is a ModuleScript that returns a function taking whatever args
		your handler passes in.

	Example:
		-- In your dialogue listener:
		controller.CommandRun:Connect(function(cmd, arg)
			local action = Actions[cmd]
			if action then action(arg) end
		end)

	Gotchas:
		- This is a placeholder that just prints. Replace the body when
		  you copy it; keeping it in a real build will spam output.
--]]

return function()
	print("HAHAHAHAHAHA")
end