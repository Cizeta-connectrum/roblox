-- ResourceManager.server.lua
-- Spawns and manages resource nodes; handles harvesting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- Resource node definitions
local NODE_TYPES = {
	tree = {
		count = 20,
		lootTable = { "wood" },
		lootMin = 1,
		lootMax = 3,
		healthMax = 3,
		toolRequired = nil, -- bare hands ok
		color = BrickColor.new("Bright green"),
		accentColor = BrickColor.new("Dark green"),
		baseSize = Vector3.new(2, 4, 2),
		topSize = Vector3.new(4, 4, 4),
		shape = "cylinder",
		respawnTime = 60,
	},
	rock = {
		count = 15,
		lootTable = { "stone" },
		lootMin = 1,
		lootMax = 3,
		healthMax = 4,
		toolRequired = nil,
		color = BrickColor.new("Mid gray"),
		baseSize = Vector3.new(4, 3, 4),
		shape = "sphere",
		respawnTime = 60,
	},
	bush = {
		count = 10,
		lootTable = { "fiber" },
		lootMin = 1,
		lootMax = 3,
		healthMax = 2,
		toolRequired = nil,
		color = BrickColor.new("Dark green"),
		baseSize = Vector3.new(3, 2, 3),
		shape = "cube",
		respawnTime = 60,
	},
}

local ResourceFolder = workspace:FindFirstChild("ResourceNodes")
if not ResourceFolder then
	ResourceFolder = Instance.new("Folder")
	ResourceFolder.Name = "ResourceNodes"
	ResourceFolder.Parent = workspace
end

-- Track node health
local nodeHealth = {}

-- Spawn a resource node
local function spawnNode(nodeType, position)
	local def = NODE_TYPES[nodeType]
	if not def then return end

	local model = Instance.new("Model")
	model.Name = nodeType .. "Node"

	if nodeType == "tree" then
		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = def.baseSize
		trunk.BrickColor = BrickColor.new("Reddish brown")
		trunk.CFrame = CFrame.new(position + Vector3.new(0, def.baseSize.Y / 2, 0))
			* CFrame.Angles(0, 0, math.pi / 2)
		trunk.Anchored = true
		trunk.Parent = model

		local top = Instance.new("Part")
		top.Name = "Top"
		top.Shape = Enum.PartType.Ball
		top.Size = def.topSize
		top.BrickColor = def.color
		top.CFrame = CFrame.new(position + Vector3.new(0, def.baseSize.Y + def.topSize.Y / 2 - 1, 0))
		top.Anchored = true
		top.Parent = model

		model.PrimaryPart = trunk
	elseif nodeType == "rock" then
		local rock = Instance.new("Part")
		rock.Name = "Rock"
		rock.Shape = Enum.PartType.Ball
		rock.Size = def.baseSize
		rock.BrickColor = def.color
		rock.CFrame = CFrame.new(position + Vector3.new(0, def.baseSize.Y / 2, 0))
		rock.Anchored = true
		rock.Parent = model

		model.PrimaryPart = rock
	elseif nodeType == "bush" then
		local bush = Instance.new("Part")
		bush.Name = "Bush"
		bush.Size = def.baseSize
		bush.BrickColor = def.color
		bush.CFrame = CFrame.new(position + Vector3.new(0, def.baseSize.Y / 2, 0))
		bush.Anchored = true
		bush.Parent = model

		model.PrimaryPart = bush
	end

	-- Metadata values
	local harvested = Instance.new("BoolValue")
	harvested.Name = "Harvested"
	harvested.Value = false
	harvested.Parent = model

	local respawnTime = Instance.new("IntValue")
	respawnTime.Name = "RespawnTime"
	respawnTime.Value = def.respawnTime
	respawnTime.Parent = model

	local typeVal = Instance.new("StringValue")
	typeVal.Name = "NodeType"
	typeVal.Value = nodeType
	typeVal.Parent = model

	local healthVal = Instance.new("IntValue")
	healthVal.Name = "Health"
	healthVal.Value = def.healthMax
	healthVal.Parent = model

	model.Parent = ResourceFolder
	nodeHealth[model] = def.healthMax

	return model
end

-- Add loot to player inventory
local function addToInventory(player, itemId, amount)
	local PlayerData = _G.PlayerData
	if not PlayerData then return end

	local data = PlayerData[player.UserId]
	if not data then return end

	local inv = data.inventory
	inv[itemId] = (inv[itemId] or 0) + amount

	-- Notify client
	RemoteEvents.UpdateInventory:FireClient(player, inv)
	print("[ResourceManager] Gave", player.Name, amount, itemId)
end

-- Harvest a node
local function harvestNode(player, model)
	if not model or not model:IsDescendantOf(workspace) then
		return false, "Invalid node"
	end

	local harvested = model:FindFirstChild("Harvested")
	local nodeTypeVal = model:FindFirstChild("NodeType")
	local healthVal = model:FindFirstChild("Health")

	if not harvested or harvested.Value then
		return false, "Already harvested"
	end

	if not nodeTypeVal then
		return false, "Not a resource node"
	end

	local def = NODE_TYPES[nodeTypeVal.Value]
	if not def then
		return false, "Unknown node type"
	end

	-- Reduce health
	healthVal.Value = healthVal.Value - 1

	if healthVal.Value > 0 then
		-- Not fully harvested yet, just give partial loot on each hit
		local lootItem = def.lootTable[math.random(1, #def.lootTable)]
		local lootAmount = 1
		addToInventory(player, lootItem, lootAmount)
		return true, "Hit"
	end

	-- Node depleted: give full loot, mark harvested, schedule respawn
	local lootItem = def.lootTable[math.random(1, #def.lootTable)]
	local lootAmount = math.random(def.lootMin, def.lootMax)
	addToInventory(player, lootItem, lootAmount)

	harvested.Value = true

	-- Hide node visually
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = 1
			part.CanCollide = false
		end
	end

	-- Schedule respawn
	local respawnDelay = def.respawnTime
	task.delay(respawnDelay, function()
		if model and model:IsDescendantOf(workspace) then
			harvested.Value = false
			healthVal.Value = def.healthMax
			nodeHealth[model] = def.healthMax
			for _, part in ipairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0
					part.CanCollide = true
				end
			end
			print("[ResourceManager] Node respawned:", model.Name)
		end
	end)

	return true, "Harvested"
end

-- Listen to harvest event
RemoteEvents.HarvestResource.OnServerEvent:Connect(function(player, nodeModel)
	local success, msg = harvestNode(player, nodeModel)
	if not success then
		warn("[ResourceManager] Harvest failed for", player.Name, ":", msg)
	end
end)

-- Spawn all nodes on startup
local MAP_SIZE = 200 -- half-extent of map

local function randomPosition()
	local x = math.random(-MAP_SIZE, MAP_SIZE)
	local z = math.random(-MAP_SIZE, MAP_SIZE)
	return Vector3.new(x, 0, z)
end

for nodeType, def in pairs(NODE_TYPES) do
	for i = 1, def.count do
		local pos = randomPosition()
		spawnNode(nodeType, pos)
	end
end

print("[ResourceManager] Resource nodes spawned.")
