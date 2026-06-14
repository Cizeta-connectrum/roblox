-- HudController.client.lua
-- Manages the HUD display: coin counter, multiplier, magnet status

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

local UpdateCoins = RemoteEvents.UpdateCoins

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentCoins = 0
local displayedCoins = 0

-- Create HUD
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "HudGui"
hudGui.ResetOnSpawn = false
hudGui.DisplayOrder = 10
hudGui.Parent = playerGui

-- Coin counter background
local coinFrame = Instance.new("Frame")
coinFrame.Name = "CoinFrame"
coinFrame.Size = UDim2.new(0, 280, 0, 70)
coinFrame.Position = UDim2.new(0.5, -140, 0, 15)
coinFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
coinFrame.BackgroundTransparency = 0.2
coinFrame.BorderSizePixel = 0
coinFrame.Parent = hudGui

local coinFrameCorner = Instance.new("UICorner")
coinFrameCorner.CornerRadius = UDim.new(0, 16)
coinFrameCorner.Parent = coinFrame

local coinFrameStroke = Instance.new("UIStroke")
coinFrameStroke.Color = Color3.fromRGB(255, 200, 0)
coinFrameStroke.Thickness = 2
coinFrameStroke.Parent = coinFrame

-- Coin icon
local coinIcon = Instance.new("TextLabel")
coinIcon.Size = UDim2.new(0, 50, 1, 0)
coinIcon.Position = UDim2.new(0, 5, 0, 0)
coinIcon.BackgroundTransparency = 1
coinIcon.Text = "🪙"
coinIcon.Font = Enum.Font.GothamBold
coinIcon.TextSize = 36
coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
coinIcon.Parent = coinFrame

-- Main coin counter
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, -60, 1, 0)
coinLabel.Position = UDim2.new(0, 55, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "0"
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 32
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.TextStrokeTransparency = 0.5
coinLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
coinLabel.Parent = coinFrame

-- Multiplier badge
local multFrame = Instance.new("Frame")
multFrame.Name = "MultiplierFrame"
multFrame.Size = UDim2.new(0, 120, 0, 35)
multFrame.Position = UDim2.new(0.5, -60, 0, 88)
multFrame.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
multFrame.BackgroundTransparency = 0.2
multFrame.BorderSizePixel = 0
multFrame.Visible = false
multFrame.Parent = hudGui

local multCorner = Instance.new("UICorner")
multCorner.CornerRadius = UDim.new(0, 10)
multCorner.Parent = multFrame

local multLabel = Instance.new("TextLabel")
multLabel.Size = UDim2.new(1, 0, 1, 0)
multLabel.BackgroundTransparency = 1
multLabel.Text = "x2 ACTIVE"
multLabel.Font = Enum.Font.GothamBold
multLabel.TextSize = 16
multLabel.TextColor3 = Color3.new(1, 1, 1)
multLabel.Parent = multFrame

-- Magnet badge
local magnetFrame = Instance.new("Frame")
magnetFrame.Name = "MagnetFrame"
magnetFrame.Size = UDim2.new(0, 140, 0, 35)
magnetFrame.Position = UDim2.new(0.5, -70, 0, 127)
magnetFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
magnetFrame.BackgroundTransparency = 0.2
magnetFrame.BorderSizePixel = 0
magnetFrame.Visible = false
magnetFrame.Parent = hudGui

local magnetCorner = Instance.new("UICorner")
magnetCorner.CornerRadius = UDim.new(0, 10)
magnetCorner.Parent = magnetFrame

local magnetLabel = Instance.new("TextLabel")
magnetLabel.Size = UDim2.new(1, 0, 1, 0)
magnetLabel.BackgroundTransparency = 1
magnetLabel.Text = "🧲 MAGNET ACTIVE"
magnetLabel.Font = Enum.Font.GothamBold
magnetLabel.TextSize = 14
magnetLabel.TextColor3 = Color3.new(1, 1, 1)
magnetLabel.Parent = magnetFrame

-- Hints frame (bottom left)
local hintsFrame = Instance.new("Frame")
hintsFrame.Size = UDim2.new(0, 220, 0, 60)
hintsFrame.Position = UDim2.new(0, 15, 1, -80)
hintsFrame.BackgroundColor3 = Color3.new(0, 0, 0)
hintsFrame.BackgroundTransparency = 0.5
hintsFrame.BorderSizePixel = 0
hintsFrame.Parent = hudGui

local hintsCorner = Instance.new("UICorner")
hintsCorner.CornerRadius = UDim.new(0, 10)
hintsCorner.Parent = hintsFrame

local hintsLabel = Instance.new("TextLabel")
hintsLabel.Size = UDim2.new(1, -10, 1, 0)
hintsLabel.Position = UDim2.new(0, 5, 0, 0)
hintsLabel.BackgroundTransparency = 1
hintsLabel.Text = "Walk near coins to collect!\nPress E near Shop to upgrade"
hintsLabel.Font = Enum.Font.Gotham
hintsLabel.TextSize = 13
hintsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
hintsLabel.TextXAlignment = Enum.TextXAlignment.Left
hintsLabel.Parent = hintsFrame

-- Coin type legend (top right)
local legendFrame = Instance.new("Frame")
legendFrame.Size = UDim2.new(0, 160, 0, 110)
legendFrame.Position = UDim2.new(1, -175, 0, 15)
legendFrame.BackgroundColor3 = Color3.new(0, 0, 0)
legendFrame.BackgroundTransparency = 0.4
legendFrame.BorderSizePixel = 0
legendFrame.Parent = hudGui

local legendCorner = Instance.new("UICorner")
legendCorner.CornerRadius = UDim.new(0, 10)
legendCorner.Parent = legendFrame

local legendTitle = Instance.new("TextLabel")
legendTitle.Size = UDim2.new(1, 0, 0, 22)
legendTitle.BackgroundTransparency = 1
legendTitle.Text = "COIN TYPES"
legendTitle.Font = Enum.Font.GothamBold
legendTitle.TextSize = 13
legendTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
legendTitle.Parent = legendFrame

local coinTypes = {
	{ name = "Common",    value = "1",   color = Color3.fromRGB(255, 215, 0) },
	{ name = "Rare",      value = "5",   color = Color3.fromRGB(0, 120, 255) },
	{ name = "Epic",      value = "20",  color = Color3.fromRGB(160, 0, 255) },
	{ name = "Legendary", value = "100", color = Color3.fromRGB(255, 165, 0) },
}

for i, ct in ipairs(coinTypes) do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -10, 0, 20)
	row.Position = UDim2.new(0, 5, 0, 20 + (i-1) * 22)
	row.BackgroundTransparency = 1
	row.Text = "● " .. ct.name .. " = +" .. ct.value
	row.Font = Enum.Font.Gotham
	row.TextSize = 13
	row.TextColor3 = ct.color
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = legendFrame
end

-- Animate coin counter
local function formatNumber(n)
	n = math.floor(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	else
		return tostring(n)
	end
end

local function animateCoinCount(targetCoins)
	-- Pop animation on frame
	TweenService:Create(coinFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 300, 0, 76)
	}):Play()
	task.delay(0.1, function()
		TweenService:Create(coinFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 280, 0, 70)
		}):Play()
	end)

	-- Smooth number tween
	local startCoins = displayedCoins
	local diff = targetCoins - startCoins
	local duration = math.min(0.5, math.abs(diff) * 0.01 + 0.1)
	local startTime = tick()

	task.spawn(function()
		while true do
			local elapsed = tick() - startTime
			local t = math.min(elapsed / duration, 1)
			-- Ease out
			local eased = 1 - (1 - t) ^ 2
			displayedCoins = startCoins + diff * eased
			coinLabel.Text = formatNumber(displayedCoins)

			if t >= 1 then
				displayedCoins = targetCoins
				coinLabel.Text = formatNumber(targetCoins)
				break
			end
			task.wait()
		end
	end)
end

UpdateCoins.OnClientEvent:Connect(function(coins, totalCoins, multiplier, magnet)
	if coins ~= currentCoins then
		animateCoinCount(coins)
		currentCoins = coins
	end

	-- Update multiplier badge
	if multiplier and multiplier > 1 then
		multFrame.Visible = true
		multLabel.Text = "x" .. tostring(multiplier) .. " ACTIVE"
	else
		multFrame.Visible = false
	end

	-- Update magnet badge
	magnetFrame.Visible = magnet == true
end)

print("HudController loaded!")
