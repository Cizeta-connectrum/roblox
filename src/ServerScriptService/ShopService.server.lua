-- ShopService.server.lua
-- Handles upgrade purchases

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

local PurchaseUpgrade = RemoteEvents.PurchaseUpgrade

-- Wait for CoinManager globals
local function waitForCoinManager()
	local attempts = 0
	while not _G.CoinManagerData and attempts < 100 do
		task.wait(0.1)
		attempts = attempts + 1
	end
	return _G.CoinManagerData
end

local CoinManagerData = waitForCoinManager()

-- Upgrade definitions
local UPGRADES = {
	speed1      = { cost = 50,   description = "Speed Boost I",       apply = function(d) d.speed = 20 end },
	speed2      = { cost = 200,  description = "Speed Boost II",      apply = function(d) d.speed = 25 end },
	speed3      = { cost = 500,  description = "Speed Boost III",     apply = function(d) d.speed = 32 end },
	radius1     = { cost = 100,  description = "Collection Radius I", apply = function(d) d.radius = 15 end },
	radius2     = { cost = 400,  description = "Collection Radius II",apply = function(d) d.radius = 22 end },
	radius3     = { cost = 1000, description = "Collection Radius III",apply = function(d) d.radius = 35 end },
	multiplier2 = { cost = 300,  description = "2x Coins",            apply = function(d) d.multiplier = 2 end },
	multiplier3 = { cost = 800,  description = "3x Coins",            apply = function(d) d.multiplier = 3 end },
	multiplier5 = { cost = 2000, description = "5x Coins",            apply = function(d) d.multiplier = 5 end },
	magnet1     = { cost = 500,  description = "Coin Magnet I",       apply = function(d) d.magnet = true; d.magnetRadius = 30 end },
	magnet2     = { cost = 1500, description = "Coin Magnet II",      apply = function(d) d.magnetRadius = 60 end },
}

PurchaseUpgrade.OnServerInvoke = function(player, upgradeId)
	local upgrade = UPGRADES[upgradeId]
	if not upgrade then
		return { success = false, message = "Unknown upgrade: " .. tostring(upgradeId) }
	end

	if not CoinManagerData then
		return { success = false, message = "Server not ready, try again!" }
	end

	local data = CoinManagerData.getPlayerData(player)

	-- Check if already purchased
	if data.purchasedUpgrades[upgradeId] then
		return { success = false, message = "Already purchased!" }
	end

	-- Check coins
	if data.coins < upgrade.cost then
		return { success = false, message = "Not enough coins! Need " .. upgrade.cost }
	end

	-- Deduct coins
	data.coins = data.coins - upgrade.cost

	-- Apply upgrade
	upgrade.apply(data)
	data.purchasedUpgrades[upgradeId] = true

	-- Apply WalkSpeed to character
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = data.speed
		end
	end

	-- Also update WalkSpeed when character respawns
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.WalkSpeed = data.speed
	end)

	-- Update coins display
	CoinManagerData.updatePlayerCoins(player)

	return {
		success = true,
		message = upgrade.description .. " purchased!"
	}
end

print("ShopService loaded!")
