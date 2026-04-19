--[[
	NetworkerUtils

	Purpose:
		Shared constants and type exports for NetworkerServer/Client. Just
		string tags and type aliases - no runtime behavior.

	When to use:
		Internal to the Networker folder. External code shouldn't need it.

	Example:
		-- inside NetworkerServer
		self:fire(players, NetworkerUtils.SET_TAG, index, value)

	Gotchas:
		- `SET_TAG` and `INSTANCE_ATTRIBUTE` names are part of the wire protocol;
		  renaming them breaks cross-version compatibility.
		- Neutral file, safe on both server and client.
]]

--[=[
	@type ClientAccess { (any) -> any }
	@within NetworkerServer
]=]
export type ClientAccess = { (...any?) -> ...any? }

--[=[
	@type NetworkTag string | Instance  
	@within NetworkerServer  
]=]
export type NetworkTag = string | Instance

export type RemotesContainer = Folder & {
	RemoteEvent: RemoteEvent,
	RemoteFunction: RemoteFunction,
}

return {
	SET_TAG = "__set",
	INSTANCE_ATTRIBUTE = "__networkTag",
	INSTANCE_TAG = "__instance",
}
