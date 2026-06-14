-- ClientMain.client.lua
-- Main client entry point: connects all controllers and handles global events

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Wait for modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))

-- Local inventory state (authoritative copy from server)
local LocalInventory = {}

-- HUD ScreenGui
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "HUD"
hudGui.ResetOnSpawn = false
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hudGui.Parent = PlayerGui

-- Day/Night label
local dayNightLabel = Instance.new("TextLabel")
dayNightLabel.Name = "DayNightLabel"
dayNightLabel.Size = UDim2.new(0, 200, 0, 40)
dayNightLabel.Position = UDim2.new(0.5, -100, 0, 10)
dayNightLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dayNightLabel.BackgroundTransparency = 0.5
dayNightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
dayNightLabel.TextScaled = true
dayNightLabel.Font = Enum.Font.GothamBold
dayNightLabel.Text = "Day"
dayNightLabel.Parent = hudGui

-- Hunger bar frame
local hungerFrame = Instance.new("Frame")
hungerFrame.Name = "HungerFrame"
hungerFrame.Size = UDim2.new(0, 200, 0, 20)
hungerFrame.Position = UDim2.new(0, 10, 1, -60)
hungerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hungerFrame.Parent = hudGui

local hungerBar = Instance.new("Frame")
hungerBar.Name = "HungerBar"
hungerBar.Size = UDim2.new(1, 0, 1, 0)
hungerBar.BackgroundColor3 = Color3.fromRGB(220, 140, 20)
hungerBar.Parent = hungerFrame

local hungerLabel = Instance.new("TextLabel")
hungerLabel.Name = "HungerLabel"
hungerLabel.Size = UDim2.new(0, 60, 0, 20)
hungerLabel.Position = UDim2.new(0, 10, 1, -85)
hungerLabel.BackgroundTransparency = 1
hungerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hungerLabel.TextScaled = true
hungerLabel.Font = Enum.Font.Gotham
hungerLabel.Text = "Hunger"
hungerLabel.Parent = hudGui

-- Expose HUD references globally for other controllers
_G.HUD = hudGui
_G.HungerBar = hungerBar
_G.LocalInventory = LocalInventory
_G.RemoteEvents = RemoteEvents

-- Listen for inventory updates from server
RemoteEvents.UpdateInventory.OnClientEvent:Connect(function(inventory)
	-- Update local inventory table in place
	for k in pairs(LocalInventory) do
		LocalInventory[k] = nil
	end
	for itemId, count in pairs(inventory) do
		LocalInventory[itemId] = count
	end

	-- Notify InventoryController if available
	if _G.OnInventoryUpdated then
		_G.OnInventoryUpdated(LocalInventory)
	end

	print("[ClientMain] Inventory updated:", inventory)
end)

-- Listen for day/night sync
RemoteEvents.DayNightSync.OnClientEvent:Connect(function(data)
	if data.isDay then
		dayNightLabel.Text = string.format("Day  %.0fs", data.dayDuration - (data.cycleTimer))
		dayNightLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	else
		local nightRemain = data.dayDuration + data.nightDuration - data.cycleTimer
		dayNightLabel.Text = string.format("Night  %.0fs", nightRemain)
		dayNightLabel.TextColor3 = Color3.fromRGB(150, 180, 255)
	end
end)

-- Listen for player death
RemoteEvents.PlayerDied.OnClientEvent:Connect(function()
	local deathLabel = Instance.new("TextLabel")
	deathLabel.Size = UDim2.new(0, 300, 0, 80)
	deathLabel.Position = UDim2.new(0.5, -150, 0.5, -40)
	deathLabel.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
	deathLabel.BackgroundTransparency = 0.3
	deathLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	deathLabel.TextScaled = true
	deathLabel.Font = Enum.Font.GothamBold
	deathLabel.Text = "YOU DIED"
	deathLabel.Parent = hudGui

	task.delay(3, function()
		deathLabel:Destroy()
	end)
end)

-- Listen for enemy spawned notifications
RemoteEvents.EnemySpawned.OnClientEvent:Connect(function(position)
	-- Could show a directional indicator — for now just log
	print("[ClientMain] Enemy spawned at", position)
end)

print("[ClientMain] Client Main initialized.")
