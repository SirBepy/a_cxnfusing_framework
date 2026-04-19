type t = {
	[string] : {
		Default : string,
		Conditioned : {
			[string] : {string},
		}
	}
}

local info : t = {
	
	DefaultRig = {
		Default = "Greeting",
	},
	
}

return info