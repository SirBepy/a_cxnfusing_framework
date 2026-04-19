local LODManager = {}

---<>--- Variables ---<>---

local rs = game:GetService("ReplicatedStorage")

local GenGUID = require(script.Parent.Parent.Functions).GenerateUID

local cc = workspace.CurrentCamera
local debrisFolder = rs:FindFirstChild("LODDebris") or Instance.new("Folder", rs)
debrisFolder.Name = "LODDebris"

local registeredCount = 0

local Registered = {}
local Batches = {}
local Config = {

	UpdateSpeed = 0.5,

	BatchUpdateDelay = 0,
	BatchSize = 10,

}

---<>--- Helper Functions ---<>---

local function getModel(ID : string) : Model

	local data = Registered[ID]
	local dist = (cc.CFrame.Position - data.CFrame.Position).Magnitude

	local bestModel = data.Models[1].Model
	local lastThreshold = -1

	for _, lodData in data.Models do
		if dist >= lodData.Distance and lodData.Distance > lastThreshold then
			bestModel = lodData.Model
			lastThreshold = lodData.Distance
		end
	end

	return bestModel
end

---<>--- Main Functions ---<>---

function LODManager:Register(CF : CFrame, Models : {
	{Model : Model | BasePart, Distance : number}
	}, Parent : Instance) : string
	if not CF or not Models then return end

	local ID = GenGUID()
	local batch = math.ceil(registeredCount+1/Config.BatchSize)

	if not Batches[batch] then Batches[batch] = {} end

	local data = {CFrame = CF, Models = Models, Parent = Parent or workspace, Batch = batch}

	Registered[ID] = data
	Batches[batch][ID] = data

	registeredCount+=1

	return ID
end

function LODManager:Deregister(ID : string)
	if not ID then return end

	local found = Registered[ID]

	if found then

		for _, model in found.Models do
			model:Destroy()
		end

		local batchNum = found.Batch

		table.clear(Batches[batchNum][ID])
		Batches[batchNum][ID] = nil

	end

	table.clear(found)
	Registered[ID] = nil

end

function LODManager:UpdateCF(ID : string, newCF : CFrame)
	if not ID or not newCF then return end
	local found = Registered[ID]
	if found then
		found.CFrame = newCF
	end
end

function LODManager:UpdateModels(ID : string, newModels : {
	{Model : Model | BasePart, Distance : number}
	}, Parent : Instance?)
	if not ID or not newModels then return end
	local found = Registered[ID]
	if found then

		for _, data in newModels do
			data.Model.Parent = debrisFolder
		end

		found.Models = newModels
		found.Parent = Parent or found.Parent

	end
end

---<>--- Initialization ---<>---

function LODManager:Init()
	task.spawn(function()
		while true do

			for _, batch in Batches do
				for id, data in batch do

					local curModel = data.CurrentModel
					local newModel = getModel(id)

					if curModel ~= newModel then
						newModel.Parent = data.Parent
						newModel:PivotTo(data.CFrame)
						if curModel then
							curModel.Parent = debrisFolder
						end
						data.CurrentModel = newModel
					end

				end
				task.wait(Config.BatchUpdateDelay)
			end

			task.wait(Config.UpdateSpeed)
		end
	end)
end

return LODManager