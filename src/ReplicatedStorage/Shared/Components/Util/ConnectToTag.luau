--[[
	ConnectToTag
	------------
	Purpose:
		CollectionService helper. Runs a callback for every instance that
		already has the tag, and for every future instance that gets tagged.

	When to use:
		- You've tagged things with CollectionService (in code or via the Tag
		  Editor) and want one place to react whenever a tagged instance shows
		  up, now or later.

	Example:
		local ConnectToTag = require(path.to.ConnectToTag)

		local conn = ConnectToTag("Enemy", function(enemy)
			-- runs immediately for any currently-tagged "Enemy" instances,
			-- and again each time a new one gets the tag
			setupEnemy(enemy)
		end)

		conn:Disconnect()

	Gotchas:
		- Only handles ADD. There's no removal hook; if you need to clean up
		  when the tag is removed, wire GetInstanceRemovedSignal yourself.
		- The returned connection covers future adds only. The initial sweep
		  over currently-tagged instances already fired by the time you get it
		  back.
		- Bad args (nil tag or callback) silently return nil.
]]

local cs = game:GetService("CollectionService")

local function connect(tag : string, callback : (Instance)->()) : RBXScriptConnection
	if not tag or not callback then return end

	-- Handle what's already tagged first, so callers don't have to double-loop.
	for _, tagged in cs:GetTagged(tag) do
		callback(tagged)
	end
	local conn = cs:GetInstanceAddedSignal(tag):Connect(callback)

	return conn
end

return connect
