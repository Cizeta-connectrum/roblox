-- CoinManager.server.lua
-- Manages coin spawning, collection, and magnet behavior

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for RemoteEvents module
local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

local UpdateCoins = RemoteEvents.UpdateCoins
local ShowCollectEffect = RemoteEvents.ShowCollectEffect
local CoinCollected = RemoteEvents.CoinCollected

-- Player data store
local playerData = {}

-- Coin types configuration
local COIN_TYPES = {
	{
		name = "Common",
		color = Color3.fromRGB(255, 215, 0),     -- Gold/Yellow
		size = 2,
		value = 1,
		weight = 60,
		material = Enum.Material.SmoothPlastic,
		emitLight = false,
	},
	{
		name = "Rare",
		color = Color3.fromRGB(0, 120, 255),      -- Blue
		size = 2.5,
		value = 5,
		weight = 25,
		material = Enum.Material.Neon,
		emitLight = false,
	},
	{
		name = "Epic",
		color = Color3.fromRGB(160, 0, 255),      -- Purple
		size = 3,
		value = 20,
		weight = 12,
		material = Enum.Material.Neon,
		emitLight = true,
	},
	{
		name = "Legendary",
		color = Color3.fromRGB(255, 165, 0),      -- Orange/Gold
		size = 4,
		value = 100,
		weight = 3,
		material = Enum.Material.Neon,
		emitLight = true,
	},
}

local MAX_COINS = 200
local SPAWN_INTERVAL = 2
local CHECK_INTERVAL = 0.5
local MAP_SIZE = 240  -- half of 500x500 map

-- Folder to hold coins
local coinsFolder = Instance.new("Folder")
coinsFolder.Name = "Coins"
coinsFolder.Parent = workspace

-- Active coins table: coinPart -> {value, coinType, id}
local activeCoins = {}

local function weightedRandom(types)
	local totalWeight = 0
	for _, t in ipairs(types) do
		totalWeight = totalWeight + t.weight
	end
	local r = math.random(1, totalWeight)
	local cumulative = 0
	for _, t in ipairs(types) do
		cumulative = cumulative + t.weight
		if r <= cumulative then
			return t
		end
	end
	return types[1]
end

local function createCoinLabel(coin, coinType)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CoinLabel"
	billboard.Size = UDim2.new(0, 60, 0, 30)
	billboard.StudsOffset = Vector3.new(0, coinType.size + 0.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = coin

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. tostring(coinType.value)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
end

local function spawnCoin()
	local coinType = weightedRandom(COIN_TYPES)

	local x = math.random(-MAP_SIZE, MAP_SIZE)
	local z = math.random(-MAP_SIZE, MAP_SIZE)
	local y = 1 + coinType.size / 2

	local coin = Instance.new("Part")
	coin.Name = "Coin_" .. coinType.name
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.5, coinType.size, coinType.size)
	coin.CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2)
	coin.Color = coinType.color
	coin.Material = coinType.material
	coin.Anchored = true
	coin.CanCollide = false
	coin.CastShadow = false

	if coinType.emitLight then
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 12
		light.Color = coinType.color
		light.Parent = coin
	end

	-- Add sparkle for legendary
	if coinType.name == "Legendary" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = coinType.color
		sparkles.Parent = coin
	end

	createCoinLabel(coin, coinType)
	coin.Parent = coinsFolder

	activeCoins[coin] = {
		value = coinType.value,
		coinType = coinType.name,
		spawnTime = tick(),
	}

	return coin
end

local function getPlayerData(player)
	if not playerData[player] then
		playerData[player] = {
			coins = 0,
			totalCoins = 0,
			speed = 16,
			radius = 10,
			multiplier = 1,
			magnet = false,
			magnetRadius = 0,
			purchasedUpgrades = {},
		}
	end
	return playerData[player]
end

local function updatePlayerCoins(player)
	local data = getPlayerData(player)
	UpdateCoins:FireClient(player, data.coins, data.totalCoins, data.multiplier, data.magnet)

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		local totalValue = leaderstats:FindFirstChild("Total")
		if coinsValue then coinsValue.Value = data.coins end
		if totalValue then totalValue.Value = data.totalCoins end
	end

	-- Fire bindable for leaderboard service
	CoinCollected:Fire(player, data.coins, data.totalCoins)
end

local function collectCoin(player, coin)
	if not activeCoins[coin] then return end

	local coinData = activeCoins[coin]
	local data = getPlayerData(player)

	local earned = coinData.value * data.multiplier
	data.coins = data.coins + earned
	data.totalCoins = data.totalCoins + earned

	local pos = coin.Position
	local coinTypeName = coinData.coinType

	-- Remove from tracking before destroying
	activeCoins[coin] = nil
	coin:Destroy()

	-- Notify all clients of collect effect
	ShowCollectEffect:FireAllClients(pos, earned, coinTypeName)

	updatePlayerCoins(player)
end

-- Player setup
Players.PlayerAdded:Connect(function(player)
	getPlayerData(player)

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = 0
	coinsValue.Parent = leaderstats

	local totalValue = Instance.new("IntValue")
	totalValue.Name = "Total"
	totalValue.Value = 0
	totalValue.Parent = leaderstats
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

-- Expose player data for other scripts
local DataModule = {}
DataModule.getPlayerData = getPlayerData
DataModule.updatePlayerCoins = updatePlayerCoins
_G.CoinManagerData = DataModule

-- Coin spinning loop
local coinSpinAngle = 0
RunService.Heartbeat:Connect(function(dt)
	coinSpinAngle = coinSpinAngle + dt * 90  -- degrees per second
	local rad = math.rad(coinSpinAngle)

	for coin, _ in pairs(activeCoins) do
		if coin and coin.Parent then
			local pos = coin.Position
			coin.CFrame = CFrame.new(pos)
				* CFrame.Angles(0, rad, math.pi / 2)
				* CFrame.new(0, math.sin(tick() * 2 + pos.X) * 0.1, 0)
		end
	end
end)

-- Coin spawner
local lastSpawn = 0
local lastCheck = 0

RunService.Heartbeat:Connect(function()
	local now = tick()

	-- Spawn coins
	if now - lastSpawn >= SPAWN_INTERVAL then
		lastSpawn = now
		local coinCount = 0
		for _ in pairs(activeCoins) do coinCount = coinCount + 1 end

		local toSpawn = math.min(5, MAX_COINS - coinCount)
		for i = 1, toSpawn do
			spawnCoin()
		end
	end

	-- Check collection and magnet
	if now - lastCheck >= CHECK_INTERVAL then
		lastCheck = now

		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			if not character then continue end

			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if not rootPart then continue end

			local data = getPlayerData(player)
			local playerPos = rootPart.Position

			for coin, coinData in pairs(activeCoins) do
				if not coin or not coin.Parent then
					activeCoins[coin] = nil
					continue
				end

				local coinPos = coin.Position
				local dist = (playerPos - coinPos).Magnitude

				-- Auto-collect if within radius
				if dist <= data.radius then
					collectCoin(player, coin)
				elseif data.magnet and dist <= data.magnetRadius then
					-- Move coin toward player (magnet effect)
					local direction = (playerPos - coinPos).Unit
					local newPos = coinPos + direction * math.min(2, dist - 1)
					coin.Position = newPos
				end
			end
		end
	end
end)

-- Initial coin spawn
for i = 1, 50 do
	spawnCoin()
end

print("CoinManager loaded!")
