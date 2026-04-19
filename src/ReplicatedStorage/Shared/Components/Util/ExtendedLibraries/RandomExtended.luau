local lib = table.clone(Random)
local extended = {}
setmetatable(extended, {__index = lib})

extended.Config = {
	Warnings = true,
}

--<>--- Helper Functions ---<>---

local function getTableType(t)
	if next(t) == nil then return "Empty" end
	local isArray = true
	local isDictionary = true
	for k, _ in next, t do
		if typeof(k) == "number" and k%1 == 0 and k > 0 then
			isDictionary = false
		else
			isArray = false
		end
	end
	if isArray then
		return "Array"
	elseif isDictionary then
		return "Dictionary"
	else
		return "Mixed"
	end
end

---<>--- Library Functions ---<>---

--[[Returns a key from a weighted table
 Example usage:
 local choice = Random.weighted({
     {name = "Common", weight = 70},
     {name = "Rare", weight = 25},
     {name = "Legendary", weight = 5},
 })]]
function extended.weighted(items : { {value: any, weight: number} }) : string
	if not items or typeof(items) ~= "table" then	error("weighted: items table required.") end
	if #items == 0 then error("weighted: More than 1 item is required.") return end

	local total = 0
	for _, item in items do
		if typeof(item.weight) ~= "number" then	error("weighted: every item needs a numeric weight.") end
		total += item.weight
	end

	if total == 0 then error("weighted: total weight cannot be 0.") end

	local rnd = math.random() * total
	local accum = 0

	for _, item in items do
		accum += item.weight
		if rnd <= accum then
			return item.value
		end
	end

	return items[#items].value
end

--Choses a random value from an array.
function extended.chooseFromArray(t : {any})
	if not t or typeof(t) ~= "table" then error("chooseFromArray: Must pass in table.") return end
	if getTableType(t) ~= "Array" then
		if extended.Config.Warnings then
			warn("chooseFromArray: table is not an array.")
		end
		return
	end
	if #t == 0 then
		if extended.Config.Warnings then
			warn("chooseFromArray: table is empty.") 
		end
		return 
	end

	local choice = t[math.random(1, #t)]

	return choice
end

--Choses a random value from a dictionary.
function extended.chooseFromDictionary(t : {any})
	if not t or typeof(t) ~= "table" then error("chooseFromDictionary: Must pass in table.") return end

	local key
	local count = 0
	
	for _, val in t do
		count+=1
	end
	
	local chosen = math.random(1,count)
	local i = 0
	
	for cKey in t do
		i+=1
		if i == chosen then
			key = cKey
		end
	end
	
	local choice = t[key]

	return choice
end

---<>---<>---

type l2 = typeof(extended)
return extended :: l2