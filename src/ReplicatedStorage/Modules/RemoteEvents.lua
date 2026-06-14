-- RemoteEvents.lua
-- Creates (server) or retrieves (client) RemoteEvents and RemoteFunctions

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

local EVENT_NAMES = {
	"HarvestResource",
	"PlaceBuilding",
	"UpdateInventory",
	"DayNightSync",
	"EnemySpawned",
	"PlayerDied",
}

local FUNCTION_NAMES = {
	"CraftItem",
}

local FOLDER_NAME = "GameRemotes"

local function getOrCreateFolder()
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	return folder
end

if RunService:IsServer() then
	-- Server: create all remotes
	local folder = getOrCreateFolder()

	for _, name in ipairs(EVENT_NAMES) do
		if not folder:FindFirstChild(name) then
			local event = Instance.new("RemoteEvent")
			event.Name = name
			event.Parent = folder
		end
	end

	for _, name in ipairs(FUNCTION_NAMES) do
		if not folder:FindFirstChild(name) then
			local func = Instance.new("RemoteFunction")
			func.Name = name
			func.Parent = folder
		end
	end

	-- Expose references
	local folder2 = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	RemoteEvents.HarvestResource = folder2:WaitForChild("HarvestResource")
	RemoteEvents.PlaceBuilding = folder2:WaitForChild("PlaceBuilding")
	RemoteEvents.UpdateInventory = folder2:WaitForChild("UpdateInventory")
	RemoteEvents.DayNightSync = folder2:WaitForChild("DayNightSync")
	RemoteEvents.EnemySpawned = folder2:WaitForChild("EnemySpawned")
	RemoteEvents.PlayerDied = folder2:WaitForChild("PlayerDied")
	RemoteEvents.CraftItem = folder2:WaitForChild("CraftItem")
else
	-- Client: wait for folder and retrieve remotes
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	RemoteEvents.HarvestResource = folder:WaitForChild("HarvestResource")
	RemoteEvents.PlaceBuilding = folder:WaitForChild("PlaceBuilding")
	RemoteEvents.UpdateInventory = folder:WaitForChild("UpdateInventory")
	RemoteEvents.DayNightSync = folder:WaitForChild("DayNightSync")
	RemoteEvents.EnemySpawned = folder:WaitForChild("EnemySpawned")
	RemoteEvents.PlayerDied = folder:WaitForChild("PlayerDied")
	RemoteEvents.CraftItem = folder:WaitForChild("CraftItem")
end

return RemoteEvents
