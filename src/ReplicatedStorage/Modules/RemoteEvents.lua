-- RemoteEvents.lua
-- Creates or retrieves all remote events/functions used in CoinSimulator

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

local function getOrCreate(className, name, parent)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local obj = Instance.new(className)
	obj.Name = name
	obj.Parent = parent
	return obj
end

if RunService:IsServer() then
	-- Server creates remotes
	RemoteEvents.UpdateCoins      = getOrCreate("RemoteEvent",    "UpdateCoins",       ReplicatedStorage)
	RemoteEvents.PurchaseUpgrade  = getOrCreate("RemoteFunction", "PurchaseUpgrade",   ReplicatedStorage)
	RemoteEvents.ShowCollectEffect= getOrCreate("RemoteEvent",    "ShowCollectEffect",  ReplicatedStorage)
	RemoteEvents.CollectCoin      = getOrCreate("RemoteEvent",    "CollectCoin",        ReplicatedStorage)
else
	-- Client waits for remotes
	RemoteEvents.UpdateCoins      = ReplicatedStorage:WaitForChild("UpdateCoins")
	RemoteEvents.PurchaseUpgrade  = ReplicatedStorage:WaitForChild("PurchaseUpgrade")
	RemoteEvents.ShowCollectEffect= ReplicatedStorage:WaitForChild("ShowCollectEffect")
	RemoteEvents.CollectCoin      = ReplicatedStorage:WaitForChild("CollectCoin")
end

return RemoteEvents
