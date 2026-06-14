-- GameManager.server.lua
-- Manages day/night cycle, player data, and zombie spawning

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents"))

-- Constants
local DAY_DURATION = 300   -- seconds
local NIGHT_DURATION = 300 -- seconds
local SYNC_INTERVAL = 10   -- seconds
local ZOMBIE_SPAWN_RADIUS_MIN = 100
local ZOMBIE_SPAWN_RADIUS_MAX = 150
local ZOMBIES_PER_PLAYER_MIN = 3
local ZOMBIES_PER_PLAYER_MAX = 5

-- Day/Night state
local isDay = true
local cycleTimer = 0
local syncTimer = 0
local totalCycleTime = DAY_DURATION + NIGHT_DURATION

-- Player data storage: [UserId] = { inventory, health, hunger }
local PlayerData = {}

local function createDefaultPlayerData()
	return {
		inventory = {},  -- [itemId] = count
		health = 100,
		hunger = 100,
	}
end

-- Setup Lighting for day
local function setDay()
	isDay = true
	Lighting.ClockTime = 12
	Lighting.Ambient = Color3.fromRGB(100, 100, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
	Lighting.Brightness = 2
	print("[GameManager] It is now DAY")
end

-- Setup Lighting for night
local function setNight()
	isDay = false
	Lighting.ClockTime = 0
	Lighting.Ambient = Color3.fromRGB(20, 20, 40)
	Lighting.OutdoorAmbient = Color3.fromRGB(30, 30, 60)
	Lighting.Brightness = 0.3
	print("[GameManager] It is now NIGHT")
end

-- Spawn a zombie NPC
local function spawnZombie(position)
	local model = Instance.new("Model")
	model.Name = "Zombie"

	local humanoidRootPart = Instance.new("Part")
	humanoidRootPart.Name = "HumanoidRootPart"
	humanoidRootPart.Size = Vector3.new(2, 2, 1)
	humanoidRootPart.CFrame = CFrame.new(position)
	humanoidRootPart.BrickColor = BrickColor.new("Dark green")
	humanoidRootPart.Anchored = false
	humanoidRootPart.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	torso.BrickColor = BrickColor.new("Dark green")
	torso.Anchored = false
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))
	head.BrickColor = BrickColor.new("Dark green")
	head.Anchored = false
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 10
	humanoid.Parent = model

	-- Weld parts together
	local weld1 = Instance.new("WeldConstraint")
	weld1.Part0 = humanoidRootPart
	weld1.Part1 = torso
	weld1.Parent = model

	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = torso
	weld2.Part1 = head
	weld2.Parent = model

	model.PrimaryPart = humanoidRootPart
	model.Parent = workspace

	-- Tag as zombie for AI
	local tag = Instance.new("BoolValue")
	tag.Name = "IsZombie"
	tag.Value = true
	tag.Parent = model

	RemoteEvents.EnemySpawned:FireAllClients(position)

	return model
end

-- Spawn zombies for all players at night start
local function spawnNightZombies()
	local playerList = Players:GetPlayers()
	if #playerList == 0 then return end

	for _, player in ipairs(playerList) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local playerPos = char.HumanoidRootPart.Position
			local count = math.random(ZOMBIES_PER_PLAYER_MIN, ZOMBIES_PER_PLAYER_MAX)
			for _ = 1, count do
				local angle = math.random() * 2 * math.pi
				local radius = math.random(ZOMBIE_SPAWN_RADIUS_MIN, ZOMBIE_SPAWN_RADIUS_MAX)
				local spawnPos = playerPos + Vector3.new(
					math.cos(angle) * radius,
					0,
					math.sin(angle) * radius
				)
				spawnZombie(spawnPos)
			end
		end
	end
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	PlayerData[player.UserId] = createDefaultPlayerData()
	print("[GameManager] Player joined:", player.Name)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			RemoteEvents.PlayerDied:FireClient(player)
			print("[GameManager] Player died:", player.Name)
		end)
	end)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	PlayerData[player.UserId] = nil
	print("[GameManager] Player left:", player.Name)
end)

-- Function to get player data (used by other scripts)
local function getPlayerData(userId)
	return PlayerData[userId]
end

-- Function to update player data
local function updatePlayerData(userId, data)
	PlayerData[userId] = data
end

-- Expose via module-like globals (other server scripts can use _G if needed)
_G.GetPlayerData = getPlayerData
_G.UpdatePlayerData = updatePlayerData
_G.PlayerData = PlayerData

-- Main game loop
local lastIsDay = true
setDay()

RunService.Heartbeat:Connect(function(dt)
	cycleTimer = cycleTimer + dt
	syncTimer = syncTimer + dt

	-- Determine day/night phase
	local currentIsDay = (cycleTimer % totalCycleTime) < DAY_DURATION

	if currentIsDay ~= lastIsDay then
		lastIsDay = currentIsDay
		if currentIsDay then
			setDay()
		else
			setNight()
			spawnNightZombies()
		end
	end

	-- Smoothly update clock time
	local fraction = (cycleTimer % totalCycleTime) / totalCycleTime
	if currentIsDay then
		-- Map 0..0.5 of cycle to daytime 6..18
		local dayFraction = (cycleTimer % totalCycleTime) / DAY_DURATION
		Lighting.ClockTime = 6 + dayFraction * 12
	else
		-- Map 0.5..1.0 of cycle to night 18..30 (6 next day)
		local nightFraction = ((cycleTimer % totalCycleTime) - DAY_DURATION) / NIGHT_DURATION
		Lighting.ClockTime = 18 + nightFraction * 12
	end

	-- Sync every SYNC_INTERVAL seconds
	if syncTimer >= SYNC_INTERVAL then
		syncTimer = 0
		RemoteEvents.DayNightSync:FireAllClients({
			isDay = currentIsDay,
			clockTime = Lighting.ClockTime,
			cycleTimer = cycleTimer % totalCycleTime,
			dayDuration = DAY_DURATION,
			nightDuration = NIGHT_DURATION,
		})
	end
end)

print("[GameManager] Game Manager initialized.")
