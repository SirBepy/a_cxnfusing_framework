local HttpService = game:GetService("HttpService")
return function()  
	local GUID = HttpService:GenerateGUID(false)
	local final = string.gsub(GUID, "-", "")
	return final
end