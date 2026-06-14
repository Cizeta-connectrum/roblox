-- CoinManager.server.lua
-- Manages coin spawning, collection, and player data for CoinSimulator

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Wait for RemoteEvents module
local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

-- BindableEvent for LeaderboardService communication
local CoinsChangedEvent = Instance.new("BindableEvent")
CoinsChangedEvent.Name = "CoinsChanged"
CoinsChangedEvent.Parent = game:GetService("ServerScriptService")

-- ============================================================
-- Constants
-- ============================================================
local MAX_COINS = 200
local SPAWN_INTERVAL = 2
local CHECK_INTERVAL = 0.5
local MAP_RADIUS = 230  -- half of 500 minus margin

local COIN_TYPES = {
	{
		name = "Common",
		color = Color3.fromRGB(255, 220, 50),   -- yellow
		size = 2,
		value = 1,
		weight = 60,
		emissive = Color3.fromRGB(255, 200, 0),
	},
	{
		name = "Rare",
		color = Color3.fromRGB(50, 120, 255),    -- blue
		size = 2.5,
		value = 5,
		weight = 25,
		emissive = Color3.fromRGB(0, 80, 255),
	},
	{
		name = "Epic",
		color = Color3.fromRGB(160, 50, 255),    -- purple
		size = 3,
		value = 20,
		weight = 12,
		emissive = Color3.fromRGB(120, 0, 220),
	},
	{
		name = "Legendary",
		color = Color3.fromRGB(255, 180, 0),     -- gold
		size = 4,
		value = 100,
		weight = 3,
		emissive = Color3.fromRGB(255, 140, 0),
	},
}

-- Build weighted table
local WEIGHT_TABLE = {}
for _, coinType in ipairs(COIN_TYPES) do
	for _ = 1, coinType.weight do
		table.insert(WEIGHT_TABLE, coinType)
	end
end

-- ============================================================
-- Player Data
-- ============================================================
local playerData = {}

local function initPlayerData(player)
	playerData[player.UserId] = {
		coins = 0,
		totalCoins = 0,
		speed = 16,
		radius = 10,
		multiplier = 1,
		magnet = false,
		magnetRadius = 0,
	}
end

local function getPlayerData(player)
	return playerData[player.UserId]
end

-- ============================================================
-- Coin Management
-- ============================================================
local activeCoins = {}   -- [coin part] = { type, value }
local coinFolder = Instance.new("Folder")
coinFolder.Name = "Coins"
coinFolder.Parent = workspace

local function pickCoinType()
	local roll = math.random(1, 100)
	return WEIGHT_TABLE[roll]
end

local function createCoinBillboard(coin, coinType)
	local bb = Instance.new("BillboardGui")
	bb.Name = "CoinLabel"
	bb.Size = UDim2.new(0, 60, 0, 30)
	bb.StudsOffset = Vector3.new(0, coinType.size + 0.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent = coin

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "+" .. tostring(coinType.value)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bb
end

local function spawnCoin()
	local coinType = pickCoinType()

	local coin = Instance.new("Part")
	coin.Name = "Coin_" .. coinType.name
	coin.Shape = Enum.PartType.Ball
	coin.Size = Vector3.new(coinType.size, coinType.size, coinType.size)
	coin.Color = coinType.color
	coin.Material = Enum.Material.Neon
	coin.CastShadow = false
	coin.Anchored = true
	coin.CanCollide = false

	-- Random position on the map
	local x = math.random(-MAP_RADIUS, MAP_RADIUS)
	local z = math.random(-MAP_RADIUS, MAP_RADIUS)
	coin.CFrame = CFrame.new(x, 2, z)

	createCoinBillboard(coin, coinType)
	coin.Parent = coinFolder

	activeCoins[coin] = { coinType = coinType, value = coinType.value }

	-- Legendary coins get a spinning light
	if coinType.name == "Legendary" then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 0)
		light.Brightness = 5
		light.Range = 12
		light.Parent = coin
	end

	return coin
end

local function destroyCoin(coin)
	activeCoins[coin] = nil
	coin:Destroy()
end

local function collectCoin(player, coin, data)
	local coinData = activeCoins[coin]
	if not coinData then return end

	local earned = coinData.value * data.multiplier
	data.coins = data.coins + earned
	data.totalCoins = data.totalCoins + earned

	local position = coin.Position
	destroyCoin(coin)

	-- Notify client for effect
	RemoteEvents.ShowCollectEffect:FireClient(player, position, earned)

	-- Update client coin display
	RemoteEvents.UpdateCoins:FireClient(player, data.coins, data.totalCoins, data.multiplier, data.magnet)

	-- Notify leaderboard
	CoinsChangedEvent:Fire(player, data.coins, data.totalCoins)
end

-- ============================================================
-- RemoteEvent: CollectCoin (client manually collects)
-- ============================================================
RemoteEvents.CollectCoin.OnServerEvent:Connect(function(player, coin)
	local data = getPlayerData(player)
	if not data then return end
	if not coin or not coin.Parent then return end
	if not activeCoins[coin] then return end

	-- Validate distance
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local dist = (rootPart.Position - coin.Position).Magnitude
	if dist <= data.radius + 5 then  -- +5 tolerance
		collectCoin(player, coin, data)
	end
end)

-- ============================================================
-- Main server loop: auto-collect, magnet, spin
-- ============================================================
local lastSpawn = 0
local lastCheck = 0
local spinAngle = 0

RunService.Heartbeat:Connect(function(dt)
	spinAngle = spinAngle + dt * 90  -- 90 degrees per second

	-- Spin coins
	for coin, coinData in pairs(activeCoins) do
		if coin and coin.Parent then
			local basePos = coin.CFrame.Position
			coin.CFrame = CFrame.new(basePos) * CFrame.Angles(0, math.rad(spinAngle), 0)
		end
	end

	local now = tick()

	-- Spawn coins
	if now - lastSpawn >= SPAWN_INTERVAL then
		lastSpawn = now
		local count = 0
		for _ in pairs(activeCoins) do count = count + 1 end
		if count < MAX_COINS then
			spawnCoin()
		end
	end

	-- Auto-collect check
	if now - lastCheck >= CHECK_INTERVAL then
		lastCheck = now

		for _, player in ipairs(Players:GetPlayers()) do
			local data = getPlayerData(player)
			if not data then continue end

			local character = player.Character
			if not character then continue end
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if not rootPart then continue end

			local playerPos = rootPart.Position
			local toCollect = {}
			local toMagnet = {}

			for coin, _ in pairs(activeCoins) do
				if coin and coin.Parent then
					local dist = (playerPos - coin.Position).Magnitude

					if dist <= data.radius then
						table.insert(toCollect, coin)
					elseif data.magnet and dist <= data.magnetRadius then
						table.insert(toMagnet, coin)
					end
				end
			end

			-- Move magnet coins toward player
			for _, coin in ipairs(toMagnet) do
				if activeCoins[coin] then
					local dir = (playerPos - coin.Position).Unit
					local newPos = coin.Position + dir * math.min(5 * CHECK_INTERVAL * 20, (playerPos - coin.Position).Magnitude)
					coin.CFrame = CFrame.new(newPos)
				end
			end

			-- Collect coins in radius
			for _, coin in ipairs(toCollect) do
				if activeCoins[coin] then
					collectCoin(player, coin, data)
				end
			end
		end
	end
end)

-- ============================================================
-- Player join/leave
-- ============================================================
Players.PlayerAdded:Connect(function(player)
	initPlayerData(player)

	player.CharacterAdded:Connect(function(character)
		local data = getPlayerData(player)
		if data then
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.WalkSpeed = data.speed
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

-- Expose playerData for ShopService
local DataModule = Instance.new("ModuleScript")
DataModule.Name = "PlayerDataAccess"
DataModule.Source = [[return require(game:GetService("ServerScriptService"):WaitForChild("CoinManager"))]]
-- Instead, store data in a shared location via BindableFunction
local GetPlayerDataFunc = Instance.new("BindableFunction")
GetPlayerDataFunc.Name = "GetPlayerData"
GetPlayerDataFunc.Parent = game:GetService("ServerScriptService")
GetPlayerDataFunc.OnInvoke = function(player)
	return playerData[player.UserId]
end

local SetPlayerDataFunc = Instance.new("BindableFunction")
SetPlayerDataFunc.Name = "SetPlayerData"
SetPlayerDataFunc.Parent = game:GetService("ServerScriptService")
SetPlayerDataFunc.OnInvoke = function(player, key, value)
	if playerData[player.UserId] then
		playerData[player.UserId][key] = value
	end
end

local NotifyClientFunc = Instance.new("BindableFunction")
NotifyClientFunc.Name = "NotifyClient"
NotifyClientFunc.Parent = game:GetService("ServerScriptService")
NotifyClientFunc.OnInvoke = function(player)
	local data = playerData[player.UserId]
	if data then
		RemoteEvents.UpdateCoins:FireClient(player, data.coins, data.totalCoins, data.multiplier, data.magnet)
	end
end

print("[CoinManager] Initialized!")
