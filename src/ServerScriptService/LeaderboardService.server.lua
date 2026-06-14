-- LeaderboardService.server.lua
-- Manages the Roblox leaderboard display

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- The leaderstats are created in CoinManager, so this service
-- just ensures they stay updated via the BindableEvent

local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

local CoinCollected = RemoteEvents.CoinCollected

CoinCollected.Event:Connect(function(player, coins, totalCoins)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsVal = leaderstats:FindFirstChild("Coins")
		local totalVal = leaderstats:FindFirstChild("Total")
		if coinsVal then coinsVal.Value = coins end
		if totalVal then totalVal.Value = totalCoins end
	end
end)

print("LeaderboardService loaded!")
