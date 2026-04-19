local cs = game:GetService("CollectionService")

local function connect(obj : Instance, callback : (Instance)->(), useDescendants : boolean) : RBXScriptConnection
	if not obj or not callback then return end

	if not useDescendants then
		for _, child in obj:GetChildren() do
			callback(child)
		end
		local conn = obj.ChildAdded:Connect(callback)

		return conn	
	else
		for _, desc in obj:GetDescendants() do
			callback(desc)
		end
		local conn = obj.DescendantAdded:Connect(callback)

		return conn	
	end
end

return connect