--[[
	DataServiceClient

	Purpose:
		Client-side mirror of the server's player data. Receives the initial
		snapshot from the server, applies replicated set/arrayInsert/arrayRemove
		ops, and exposes the same read API plus change signals for UI to bind to.

	When to use:
		In any LocalScript that needs to read player data or react to changes
		(HUD, inventory UIs, settings menus, tutorial steppers).

	Example:
		local DataService = require(path.to.DataService).client
		DataService:init()
		print(DataService:get({ "currency" }))
		DataService:getChangedSignal({ "currency" }):Connect(function(new)
			updateCurrencyLabel(new)
		end)

	Gotchas:
		- CLIENT-ONLY. Requiring `.client` on the server hits the stub return
		  below and every method will be nil. Use `.server` on the server.
		- `:init(...)` yields until the server has sent the initial snapshot.
		  Don't call read methods before init finishes or you'll yield in them
		  via waitForData.
		- `:set`, `:update`, `:arrayInsert`, `:arrayRemove` on the client only
		  mutate the LOCAL mirror - they do NOT replicate back to the server.
		  Use these for purely client-side UI state / predictions.
]]

local RunService = game:GetService("RunService")

if RunService:IsServer() then
	-- Server import of the client module: hand back an empty stub. The paired
	-- `.server` module is what server code should use. See `init.luau`.
	return {} :: DataServiceClient
end

local Packages = script.Parent
local Signal = require(Packages.Signal)
local Networker = require(Packages.Networker)
local DataServiceUtils = require(script.Parent.DataServiceUtils)
local Data = require(script.Parent.Data)

type Signal<T> = Signal.Signal<T>
type Path = Data.Path

local waitSignal = Signal.new()

--[=[
	@class DataServiceClient
	The client-side service for managing player data.
]=]
local DataServiceClient = {
	_data = nil :: Data.Data<any>?,
}

--[=[
	@within DataServiceClient
	@method init
	@yields

	Initializes the DataServiceClient.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:init()
	```

	:::warning
	`:init(...)` must be called before using any other methods. Init yields until it has received the initial data from the server.
	:::
]=]
function DataServiceClient.init(self: DataServiceClient, data: any?)
	self.networker = Networker.client.new("DataService", self)

	if data then
		self:_initData(data)
	end

	self:waitForData()
end

--[=[
	@within DataServiceClient
	@method fetch
	@yields
	@param path Path?
	@param dontSet boolean? -- Default: false
	@return any

	Fetches data from the server at the specified path. Sets the data locally unless `dontSet` is true.

	```lua
	local DataService = require(path.to.DataService).client
	local fetchedCurrency = DataService:fetch({ "currency" })
	```

	:::note
	Typically only useful if you somehow desynced your local data with the server. Otherwise, you should use `DataService:get(path)` to retrieve data.
	:::
]=]
function DataServiceClient.fetch(self: DataServiceClient, path: Path?, dontSet: boolean?): any
	local value = self.networker:fetch("get", path)
	if not dontSet then
		self._data:set(path, value)
	end
	return value
end

--[=[
	@within DataServiceClient
	@method get
	@param path Path?
	@return any

	Retrieves the data at the specified path.

	```lua
	local DataService = require(path.to.DataService).client
	local currency = DataService:get({ "currency" })
	```

	:::warning
	If you attempt to call this method before the data is initialized, it will yield until the data is available.
	:::
]=]
function DataServiceClient.get(self: DataServiceClient, path: Path?): any
	self:waitForData()
	return self._data:get(path)
end

--[=[
	@within DataServiceClient
	@method set
	@param path Path
	@param value any

	Sets the data at the specified path to the given value.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:set({ "settings", "music" }, 25)
	```

	:::note
	This does NOT replicate data to the server. Useful for local data manipulation, such as client-controlled Settings or states.
	:::
]=]
function DataServiceClient.set(self: DataServiceClient, path: Path, value: any)
	self._data:set(path, value)
end

--[=[
	@within DataServiceClient
	@method update
	@param path Path
	@param callback (any) -> any
	@return any

	Updates the data at the specified path using the provided callback function.

	```lua
	local DataService = require(path.to.DataService).client
	local updatedMusicVolume = DataService:update({ "settings", "music" }, function(currentValue)
		return currentValue + 10
	end)
	```

	:::note
	This does NOT replicate data to the server. Useful for local data manipulation.
	:::
]=]
function DataServiceClient.update(self: DataServiceClient, path: Path, callback: (any) -> any): any
	return self._data:update(path, callback)
end

--[=[
	@within DataServiceClient
	@method arrayInsert
	@param path Path
	@param value any
	@param index number? -- Default: nil

	Inserts a value into an array at the specified path. If `index` is provided, it inserts at that index; otherwise, it appends to the end.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:arrayInsert({ "inventory" }, "newItem", 1)
	```

	:::note
	This does NOT replicate data to the server. Useful for local data manipulation for immediate UI updates.
	:::
]=]
function DataServiceClient.arrayInsert(self: DataServiceClient, path: Path, value: any, index: number?)
	self._data:arrayInsert(path, value, index)
end

--[=[
	@within DataServiceClient
	@method arrayRemove
	@param path Path
	@param index number

	Removes an item from an array at the specified path by its index.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:arrayRemove({ "inventory" }, 1)
	```

	:::note
	This does NOT replicate data to the server. Useful for local data manipulation for immediate UI updates.
	:::
]=]
function DataServiceClient.arrayRemove(self: DataServiceClient, path: Path, index: number): any
	return self._data:arrayRemove(path, index)
end

--[=[
	@within DataServiceClient
	@method getChangedSignal
	@param path Path
	@return Signal<any>

	Retrieves a signal that fires when the value at the specified path changes.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:getChangedSignal({ "currency" }):Connect(function(newValue)
		print("Currency changed to:", newValue)
	end)
	```
]=]
function DataServiceClient.getChangedSignal(self: DataServiceClient, path: Path): Signal<any>
	return self._data:getChangedSignal(path)
end

--[=[
	@within DataServiceClient
	@method getIndexChangedSignal
	@param path Path
	@return Signal<any>

	Retrieves a signal that fires when any child at the specified path changes.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:getIndexChangedSignal({ "tutorial" }):Connect(function(index, newValue)
		print("Tutorial changed at index", index, "changed to:", newValue)
	end)
	```
]=]
function DataServiceClient.getIndexChangedSignal(self: DataServiceClient, path: Path): Signal<any>
	return self._data:getIndexChangedSignal(path)
end

--[=[
	@within DataServiceClient
	@method getArrayInsertedSignal
	@param path Path
	@return Signal<any>

	Retrieves a signal that fires when an item is inserted into an array at the specified path.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:getArrayInsertedSignal({ "inventory" }):Connect(function(index, value)
		print("Item inserted at index", index, "with value:", value)
	end)
	```
]=]
function DataServiceClient.getArrayInsertedSignal(self: DataServiceClient, path: Path): Signal<any>
	return self._data:getArrayInsertedSignal(path)
end

--[=[
	@within DataServiceClient
	@method getArrayRemovedSignal
	@param path Path
	@return Signal<any>

	Retrieves a signal that fires when an item is removed from an array at the specified path.

	```lua
	local DataService = require(path.to.DataService).client
	DataService:getArrayRemovedSignal({ "inventory" }):Connect(function(index, value)
		print("Item removed from index", index, "with value:", value)
	end)
	```
]=]
function DataServiceClient.getArrayRemovedSignal(self: DataServiceClient, path: Path): Signal<any>
	return self._data:getArrayRemovedSignal(path)
end

--[=[
	@within DataServiceClient
	@method waitForData
	@yields
	@return any

	Waits for the data to be initialized and returns it.
]=]
function DataServiceClient.waitForData(self: DataServiceClient): any
	local data = self._data
	if data then
		return data
	end

	waitSignal:Wait()
	return self._data
end

function DataServiceClient._initData(self: DataServiceClient, data: any): ()
	assert(self._data == nil, "DataServiceClient: Data already initialized")
	self._data = Data.new(data)
	waitSignal:Fire()
end

-- Expose the mutation methods under their numeric enum keys too. The server
-- fires replication messages using the enum ids (smaller payload than method
-- names), and NetworkerClient dispatches by looking up `module[method]` - so
-- these alias rows are what make the replication actually land.
DataServiceClient[DataServiceUtils.enums.actions.set] = DataServiceClient.set
DataServiceClient[DataServiceUtils.enums.actions.arrayInsert] = DataServiceClient.arrayInsert
DataServiceClient[DataServiceUtils.enums.actions.arrayRemove] = DataServiceClient.arrayRemove
DataServiceClient[DataServiceUtils.enums.actions.init] = DataServiceClient._initData

export type DataServiceClient = typeof(DataServiceClient)

return DataServiceClient
