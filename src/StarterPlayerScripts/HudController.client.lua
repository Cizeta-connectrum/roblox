-- HudController.client.lua
-- Manages the heads-up display for CoinSimulator

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))

-- ============================================================
-- Build HUD ScreenGui
-- ============================================================
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "HudGui"
hudGui.ResetOnSpawn = false
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hudGui.Parent = playerGui

-- Main coin display frame (top center)
local coinFrame = Instance.new("Frame")
coinFrame.Name = "CoinFrame"
coinFrame.Size = UDim2.new(0, 280, 0, 60)
coinFrame.Position = UDim2.new(0.5, -140, 0, 10)
coinFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
coinFrame.BackgroundTransparency = 0.15
coinFrame.BorderSizePixel = 0
coinFrame.Parent = hudGui

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 12)
coinCorner.Parent = coinFrame

local coinStroke = Instance.new("UIStroke")
coinStroke.Color = Color3.fromRGB(255, 200, 0)
coinStroke.Thickness = 2
coinStroke.Parent = coinFrame

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, -10, 1, 0)
coinLabel.Position = UDim2.new(0, 5, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "🪙 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextXAlignment = Enum.TextXAlignment.Center
coinLabel.Parent = coinFrame

-- Status bar (below coin frame): multiplier + magnet
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0, 280, 0, 36)
statusFrame.Position = UDim2.new(0.5, -140, 0, 76)
statusFrame.BackgroundTransparency = 1
statusFrame.BorderSizePixel = 0
statusFrame.Parent = hudGui

local statusLayout = Instance.new("UIListLayout")
statusLayout.FillDirection = Enum.FillDirection.Horizontal
statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
statusLayout.Padding = UDim.new(0, 6)
statusLayout.Parent = statusFrame

-- Multiplier badge
local multiplierBadge = Instance.new("Frame")
multiplierBadge.Name = "MultiplierBadge"
multiplierBadge.Size = UDim2.new(0, 120, 0, 32)
multiplierBadge.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
multiplierBadge.BackgroundTransparency = 0.2
multiplierBadge.BorderSizePixel = 0
multiplierBadge.Visible = false
multiplierBadge.Parent = statusFrame

local multCorner = Instance.new("UICorner")
multCorner.CornerRadius = UDim.new(0, 8)
multCorner.Parent = multiplierBadge

local multiplierLabel = Instance.new("TextLabel")
multiplierLabel.Size = UDim2.new(1, 0, 1, 0)
multiplierLabel.BackgroundTransparency = 1
multiplierLabel.Text = "x2 ACTIVE"
multiplierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
multiplierLabel.TextScaled = true
multiplierLabel.Font = Enum.Font.GothamBold
multiplierLabel.Parent = multiplierBadge

-- Magnet badge
local magnetBadge = Instance.new("Frame")
magnetBadge.Name = "MagnetBadge"
magnetBadge.Size = UDim2.new(0, 140, 0, 32)
magnetBadge.BackgroundColor3 = Color3.fromRGB(180, 0, 200)
magnetBadge.BackgroundTransparency = 0.2
magnetBadge.BorderSizePixel = 0
magnetBadge.Visible = false
magnetBadge.Parent = statusFrame

local magCorner = Instance.new("UICorner")
magCorner.CornerRadius = UDim.new(0, 8)
magCorner.Parent = magnetBadge

local magnetLabel = Instance.new("TextLabel")
magnetLabel.Size = UDim2.new(1, 0, 1, 0)
magnetLabel.BackgroundTransparency = 1
magnetLabel.Text = "🧲 MAGNET ACTIVE"
magnetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
magnetLabel.TextScaled = true
magnetLabel.Font = Enum.Font.GothamBold
magnetLabel.Parent = magnetBadge

-- ============================================================
-- Coin count formatting helper
-- ============================================================
local function formatNumber(n)
	local s = tostring(math.floor(n))
	local result = ""
	local len = #s
	for i = 1, len do
		result = result .. s:sub(i, i)
		if (len - i) % 3 == 0 and i ~= len then
			result = result .. ","
		end
	end
	return result
end

-- ============================================================
-- Update HUD
-- ============================================================
local currentDisplayedCoins = 0

local function updateHud(coins, totalCoins, multiplier, magnet)
	-- Tween coin counter
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- We'll just update the text; a "pop" scale tween on the frame
	coinLabel.Text = "🪙 " .. formatNumber(coins)

	-- Pop animation on the coin frame
	local popTween = TweenService:Create(coinFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 300, 0, 68),
		Position = UDim2.new(0.5, -150, 0, 6),
	})
	popTween:Play()
	popTween.Completed:Connect(function()
		local restoreTween = TweenService:Create(coinFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 280, 0, 60),
			Position = UDim2.new(0.5, -140, 0, 10),
		})
		restoreTween:Play()
	end)

	-- Multiplier badge
	if multiplier and multiplier > 1 then
		multiplierBadge.Visible = true
		multiplierLabel.Text = "x" .. tostring(multiplier) .. " ACTIVE"
	else
		multiplierBadge.Visible = false
	end

	-- Magnet badge
	magnetBadge.Visible = magnet == true

	currentDisplayedCoins = coins
end

-- ============================================================
-- Listen for coin updates from server
-- ============================================================
RemoteEvents.UpdateCoins.OnClientEvent:Connect(function(coins, totalCoins, multiplier, magnet)
	updateHud(coins, totalCoins, multiplier, magnet)
end)

-- ============================================================
-- Floating text effects triggered by ShowCollectEffect
-- (secondary display in screen space — world-space handled by CoinController)
-- ============================================================
-- No duplicate here; CoinController handles world-space effects.
-- HudController could show screen-space notifications if desired.
