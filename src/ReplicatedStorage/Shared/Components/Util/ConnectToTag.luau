local cs = game:GetService("CollectionService")

local function connect(tag : string, callback : (Instance)->()) : RBXScriptConnection
	if not tag or not callback then return end
	
	for _, tagged in cs:GetTagged(tag) do
		callback(tagged)
	end
	local conn = cs:GetInstanceAddedSignal(tag):Connect(callback)
	
	return conn	
end

return connect