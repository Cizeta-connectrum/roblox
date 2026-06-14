-- RemoteEvents.lua
-- Creates/gets remote events and functions for the Coin Simulator

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local obj = Instance.new(className)
	obj.Name = name
	obj.Parent = parent
	return obj
end

local RemoteEvents = {}

-- UpdateCoins: Server -> Client, args: (coins: number, totalCoins: number, multiplier: number, magnet: bool)
RemoteEvents.UpdateCoins = getOrCreate(ReplicatedStorage, "RemoteEvent", "UpdateCoins")

-- PurchaseUpgrade: Client -> Server function, args: (upgradeId: string) returns {success, message}
RemoteEvents.PurchaseUpgrade = getOrCreate(ReplicatedStorage, "RemoteFunction", "PurchaseUpgrade")

-- ShowCollectEffect: Server -> Client, args: (position: Vector3, value: number, coinType: string)
RemoteEvents.ShowCollectEffect = getOrCreate(ReplicatedStorage, "RemoteEvent", "ShowCollectEffect")

-- CoinCollected: BindableEvent for internal server use
RemoteEvents.CoinCollected = getOrCreate(ReplicatedStorage, "BindableEvent", "CoinCollected")

return RemoteEvents
