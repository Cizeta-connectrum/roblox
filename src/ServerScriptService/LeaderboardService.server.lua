-- LeaderboardService.server.lua
-- Manages the standard Roblox leaderstats board for CoinSimulator

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for CoinsChanged BindableEvent from CoinManager
local CoinsChanged = ServerScriptService:WaitForChild("CoinsChanged")

-- Table to hold leaderstats IntValues per player
local leaderData = {}  -- [userId] = { coinsValue, totalValue }

local function setupLeaderstats(player)
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

	leaderData[player.UserId] = {
		coinsValue = coinsValue,
		totalValue = totalValue,
	}
end

Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	leaderData[player.UserId] = nil
end)

-- Handle existing players (in case service loads late)
for _, player in ipairs(Players:GetPlayers()) do
	if not leaderData[player.UserId] then
		setupLeaderstats(player)
	end
end

-- Listen for coin changes from CoinManager
CoinsChanged.Event:Connect(function(player, coins, totalCoins)
	local entry = leaderData[player.UserId]
	if entry then
		entry.coinsValue.Value = coins
		entry.totalValue.Value = totalCoins
	end
end)

print("[LeaderboardService] Initialized!")
