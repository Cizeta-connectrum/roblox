-- BuildingService.server.lua
-- Handles placing buildings in the world

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents"))
local ItemData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemData"))

-- Building definitions: how each building item looks in the world
local BUILDING_VISUALS = {
	wall = {
		size = Vector3.new(8, 6, 0.5),
		color = BrickColor.new("Tan"),
		material = Enum.Material.Wood,
	},
	floor = {
		size = Vector3.new(8, 0.5, 8),
		color = BrickColor.new("Tan"),
		material = Enum.Material.Wood,
	},
	campfire = {
		size = Vector3.new(2, 1, 2),
		color = BrickColor.new("Dark orange"),
		material = Enum.Material.SmoothPlastic,
		hasLight = true,
	},
}

-- Folder for placed buildings
local BuildingsFolder = workspace:FindFirstChild("Buildings")
if not BuildingsFolder then
	BuildingsFolder = Instance.new("Folder")
	BuildingsFolder.Name = "Buildings"
	BuildingsFolder.Parent = workspace
end

-- Remove item from inventory
local function removeFromInventory(player, itemId, amount)
	local PlayerData = _G.PlayerData
	if not PlayerData then return false end

	local data = PlayerData[player.UserId]
	if not data then return false end

	local inv = data.inventory
	local current = inv[itemId] or 0
	if current < amount then return false end

	inv[itemId] = current - amount
	if inv[itemId] <= 0 then
		inv[itemId] = nil
	end

	RemoteEvents.UpdateInventory:FireClient(player, inv)
	return true
end

-- Place a building
local function placeBuilding(player, itemId, cframe)
	local PlayerData = _G.PlayerData
	if not PlayerData then
		return false, "Server not ready"
	end

	local data = PlayerData[player.UserId]
	if not data then
		return false, "Player data not found"
	end

	-- Check item type is a building
	local itemDef = ItemData.Items[itemId]
	if not itemDef or itemDef.itemType ~= "building" then
		return false, "Not a building item"
	end

	-- Check player has item
	local inv = data.inventory
	if (inv[itemId] or 0) < 1 then
		return false, "No " .. itemId .. " in inventory"
	end

	-- Check visual definition
	local visual = BUILDING_VISUALS[itemId]
	if not visual then
		return false, "No visual definition for " .. itemId
	end

	-- Validate CFrame (basic sanity check)
	if typeof(cframe) ~= "CFrame" then
		return false, "Invalid CFrame"
	end

	-- Create the building part
	local model = Instance.new("Model")
	model.Name = itemId .. "_Building"

	local part = Instance.new("Part")
	part.Name = "Structure"
	part.Size = visual.size
	part.BrickColor = visual.color
	part.Material = visual.material
	part.CFrame = cframe
	part.Anchored = true
	part.Parent = model

	-- Add campfire light if applicable
	if visual.hasLight then
		local fire = Instance.new("Fire")
		fire.Parent = part

		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 5
		pointLight.Range = 20
		pointLight.Color = Color3.fromRGB(255, 140, 0)
		pointLight.Parent = part
	end

	-- Tag who built it
	local builderVal = Instance.new("StringValue")
	builderVal.Name = "Builder"
	builderVal.Value = player.Name
	builderVal.Parent = model

	local typeVal = Instance.new("StringValue")
	typeVal.Name = "BuildingType"
	typeVal.Value = itemId
	typeVal.Parent = model

	model.PrimaryPart = part
	model.Parent = BuildingsFolder

	-- Remove item from inventory
	removeFromInventory(player, itemId, 1)

	print("[BuildingService]", player.Name, "placed", itemId, "at", cframe.Position)
	return true, "Placed"
end

-- Listen to PlaceBuilding event
RemoteEvents.PlaceBuilding.OnServerEvent:Connect(function(player, itemId, cframe)
	local success, msg = placeBuilding(player, itemId, cframe)
	if not success then
		warn("[BuildingService] Place failed for", player.Name, ":", msg)
	end
end)

print("[BuildingService] Building Service initialized.")
