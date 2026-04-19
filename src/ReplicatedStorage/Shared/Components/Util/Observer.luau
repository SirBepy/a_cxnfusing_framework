local Observer = {}
Observer.__index = Observer

export type Main = typeof(Observer)

function Observer.new(tabl: {}, callback)

	local proxy = newproxy(true)
	local metatable = getmetatable(proxy)

	metatable.__index = tabl
	metatable.__newindex = function(_, index, value)
		if tabl[index] == value then return end
		tabl[index] = value
		callback(index, value)
	end

	return proxy
end

return Observer