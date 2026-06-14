-- ShopService.server.lua
-- Handles upgrade purchases for CoinSimulator

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for CoinManager to set up its BindableFunctions
local GetPlayerData  = ServerScriptService:WaitForChild("GetPlayerData")
local SetPlayerData  = ServerScriptService:WaitForChild("SetPlayerData")
local NotifyClient   = ServerScriptService:WaitForChild("NotifyClient")
local CoinsChanged   = ServerScriptService:WaitForChild("CoinsChanged")

local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

-- ============================================================
-- Upgrade definitions
-- ============================================================
local UPGRADES = {
	speed1      = { cost = 50,   action = function(d) d.speed = 20  end, label = "Speed I" },
	speed2      = { cost = 200,  action = function(d) d.speed = 25  end, label = "Speed II" },
	speed3      = { cost = 500,  action = function(d) d.speed = 32  end, label = "Speed III" },
	radius1     = { cost = 100,  action = function(d) d.radius = 15  end, label = "Radius I" },
	radius2     = { cost = 400,  action = function(d) d.radius = 22  end, label = "Radius II" },
	radius3     = { cost = 1000, action = function(d) d.radius = 35  end, label = "Radius III" },
	multiplier2 = { cost = 300,  action = function(d) d.multiplier = 2  end, label = "x2 Multiplier" },
	multiplier3 = { cost = 800,  action = function(d) d.multiplier = 3  end, label = "x3 Multiplier" },
	multiplier5 = { cost = 2000, action = function(d) d.multiplier = 5  end, label = "x5 Multiplier" },
	magnet1     = { cost = 500,  action = function(d) d.magnet = true; d.magnetRadius = 30  end, label = "Magnet I" },
	magnet2     = { cost = 1500, action = function(d) d.magnetRadius = 60  end, label = "Magnet II" },
}

-- ============================================================
-- Handle purchase
-- ============================================================
RemoteEvents.PurchaseUpgrade.OnServerInvoke = function(player, upgradeId)
	local upgrade = UPGRADES[upgradeId]
	if not upgrade then
		return { success = false, message = "Unknown upgrade." }
	end

	local data = GetPlayerData:Invoke(player)
	if not data then
		return { success = false, message = "Player data not found." }
	end

	if data.coins < upgrade.cost then
		return { success = false, message = "Not enough coins! Need " .. upgrade.cost .. " coins." }
	end

	-- Deduct cost and apply upgrade
	data.coins = data.coins - upgrade.cost
	upgrade.action(data)

	-- Apply walk speed immediately if character exists
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = data.speed
		end
	end

	-- Notify client of new coin count
	NotifyClient:Invoke(player)

	-- Notify leaderboard
	CoinsChanged:Fire(player, data.coins, data.totalCoins)

	return {
		success = true,
		message = upgrade.label .. " purchased! (-" .. upgrade.cost .. " coins)",
	}
end

print("[ShopService] Initialized!")
