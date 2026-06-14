-- ShopController.client.lua
-- Handles the shop UI and upgrade purchases

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

local PurchaseUpgrade = RemoteEvents.PurchaseUpgrade
local UpdateCoins = RemoteEvents.UpdateCoins

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentCoins = 0
local purchasedUpgrades = {}
local shopOpen = false

-- Upgrade definitions for UI
local UPGRADES = {
	{ id = "speed1",      cost = 50,   name = "Speed Boost I",        desc = "Move faster",                  icon = "⚡" },
	{ id = "speed2",      cost = 200,  name = "Speed Boost II",       desc = "Move even faster",             icon = "⚡⚡" },
	{ id = "speed3",      cost = 500,  name = "Speed Boost III",      desc = "Blazing fast speed",           icon = "⚡⚡⚡" },
	{ id = "radius1",     cost = 100,  name = "Collection Radius I",  desc = "Collect coins from farther",   icon = "🔵" },
	{ id = "radius2",     cost = 400,  name = "Collection Radius II", desc = "Large collection area",        icon = "🔵🔵" },
	{ id = "radius3",     cost = 1000, name = "Collection Radius III",desc = "Massive collection area",      icon = "🔵🔵🔵" },
	{ id = "multiplier2", cost = 300,  name = "2x Coins",             desc = "Double all coin values",       icon = "x2" },
	{ id = "multiplier3", cost = 800,  name = "3x Coins",             desc = "Triple all coin values",       icon = "x3" },
	{ id = "multiplier5", cost = 2000, name = "5x Coins",             desc = "5x all coin values",           icon = "x5" },
	{ id = "magnet1",     cost = 500,  name = "Coin Magnet I",        desc = "Coins fly toward you",         icon = "🧲" },
	{ id = "magnet2",     cost = 1500, name = "Coin Magnet II",       desc = "Stronger magnet, more range",  icon = "🧲🧲" },
}

-- Build shop UI
local function createShopUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopGui"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 550, 0, 600)
	mainFrame.Position = UDim2.new(0.5, -275, 0.5, -300)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 16)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Color3.fromRGB(255, 200, 0)
	mainStroke.Thickness = 2
	mainStroke.Parent = mainFrame

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 60)
	titleBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = mainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 14)
	titleCorner.Parent = titleBar

	-- Fix bottom corners of title bar
	local titleFix = Instance.new("Frame")
	titleFix.Size = UDim2.new(1, 0, 0.5, 0)
	titleFix.Position = UDim2.new(0, 0, 0.5, 0)
	titleFix.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	titleFix.BorderSizePixel = 0
	titleFix.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🪙 COIN SHOP"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 26
	titleLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -50, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Parent = mainFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 8)
	closeBtnCorner.Parent = closeBtn

	-- Coins display
	local coinsDisplay = Instance.new("TextLabel")
	coinsDisplay.Name = "CoinsDisplay"
	coinsDisplay.Size = UDim2.new(1, -20, 0, 35)
	coinsDisplay.Position = UDim2.new(0, 10, 0, 65)
	coinsDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	coinsDisplay.Text = "🪙 Coins: 0"
	coinsDisplay.Font = Enum.Font.GothamBold
	coinsDisplay.TextSize = 20
	coinsDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsDisplay.Parent = mainFrame

	local coinsCorner = Instance.new("UICorner")
	coinsCorner.CornerRadius = UDim.new(0, 8)
	coinsCorner.Parent = coinsDisplay

	-- Scroll frame for upgrades
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "UpgradeScroll"
	scrollFrame.Size = UDim2.new(1, -20, 1, -115)
	scrollFrame.Position = UDim2.new(0, 10, 0, 108)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = scrollFrame

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingBottom = UDim.new(0, 6)
	scrollPadding.Parent = scrollFrame

	-- Status message
	local statusMsg = Instance.new("TextLabel")
	statusMsg.Name = "StatusMessage"
	statusMsg.Size = UDim2.new(1, -20, 0, 30)
	statusMsg.Position = UDim2.new(0, 10, 1, -35)
	statusMsg.BackgroundTransparency = 1
	statusMsg.Text = ""
	statusMsg.Font = Enum.Font.Gotham
	statusMsg.TextSize = 16
	statusMsg.TextColor3 = Color3.fromRGB(100, 255, 100)
	statusMsg.Parent = mainFrame

	-- Button references for updating
	local upgradeButtons = {}

	local function showStatus(msg, success)
		statusMsg.Text = msg
		statusMsg.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
		task.delay(3, function()
			if statusMsg.Text == msg then
				statusMsg.Text = ""
			end
		end)
	end

	local function updateButtons()
		for _, info in ipairs(upgradeButtons) do
			local btn = info.button
			local costLabel = info.costLabel

			if purchasedUpgrades[info.id] then
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				costLabel.Text = "✓ OWNED"
				costLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
				btn.Active = false
			elseif currentCoins >= info.cost then
				btn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
			else
				btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
			end
		end

		coinsDisplay.Text = "🪙 Coins: " .. tostring(math.floor(currentCoins))
	end

	-- Create upgrade buttons
	for i, upgrade in ipairs(UPGRADES) do
		local btn = Instance.new("TextButton")
		btn.Name = upgrade.id
		btn.Size = UDim2.new(1, -8, 0, 65)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.LayoutOrder = i
		btn.Parent = scrollFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(80, 80, 120)
		btnStroke.Thickness = 1
		btnStroke.Parent = btn

		-- Icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 50, 1, 0)
		iconLabel.Position = UDim2.new(0, 5, 0, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = upgrade.icon
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.TextSize = 22
		iconLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		iconLabel.Parent = btn

		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -130, 0, 32)
		nameLabel.Position = UDim2.new(0, 60, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = upgrade.name
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = btn

		-- Desc label
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -130, 0, 22)
		descLabel.Position = UDim2.new(0, 60, 0, 36)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = upgrade.desc
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 13
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = btn

		-- Cost label
		local costLabel = Instance.new("TextLabel")
		costLabel.Name = "CostLabel"
		costLabel.Size = UDim2.new(0, 100, 1, 0)
		costLabel.Position = UDim2.new(1, -110, 0, 0)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = "🪙 " .. tostring(upgrade.cost)
		costLabel.Font = Enum.Font.GothamBold
		costLabel.TextSize = 16
		costLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		costLabel.Parent = btn

		table.insert(upgradeButtons, { button = btn, costLabel = costLabel, id = upgrade.id, cost = upgrade.cost })

		btn.MouseButton1Click:Connect(function()
			if purchasedUpgrades[upgrade.id] then
				showStatus("Already purchased!", false)
				return
			end
			if currentCoins < upgrade.cost then
				showStatus("Not enough coins! Need 🪙" .. upgrade.cost, false)
				return
			end

			-- Optimistic UI
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

			local result = PurchaseUpgrade:InvokeServer(upgrade.id)
			if result and result.success then
				purchasedUpgrades[upgrade.id] = true
				showStatus("✓ " .. result.message, true)
				updateButtons()
			else
				showStatus("✗ " .. (result and result.message or "Purchase failed!"), false)
				updateButtons()
			end
		end)

		-- Hover effects
		btn.MouseEnter:Connect(function()
			if not purchasedUpgrades[upgrade.id] then
				TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(60, 60, 100) }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			updateButtons()
		end)
	end

	-- Update coins display when coins change
	UpdateCoins.OnClientEvent:Connect(function(coins, totalCoins, multiplier, magnet)
		currentCoins = coins
		updateButtons()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
		shopOpen = false
	end)

	return screenGui, updateButtons
end

local shopGui, updateShopButtons = createShopUI()

-- Toggle shop with E key when near shop part
local function isNearShop()
	local character = player.Character
	if not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local shopPart = workspace:FindFirstChild("ShopPart")
	if not shopPart then return false end

	return (root.Position - shopPart.Position).Magnitude <= 20
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		if shopOpen then
			shopGui.Enabled = false
			shopOpen = false
		elseif isNearShop() then
			shopGui.Enabled = true
			shopOpen = true
		end
	end
	if input.KeyCode == Enum.KeyCode.Escape and shopOpen then
		shopGui.Enabled = false
		shopOpen = false
	end
end)

-- Show proximity prompt on shop
local function setupShopPrompt()
	local shopPart = workspace:WaitForChild("ShopPart", 10)
	if not shopPart then return end

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.ActionText = "Open Shop"
	proximityPrompt.ObjectText = "Coin Shop"
	proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E
	proximityPrompt.MaxActivationDistance = 20
	proximityPrompt.Parent = shopPart

	proximityPrompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player then
			shopGui.Enabled = not shopGui.Enabled
			shopOpen = shopGui.Enabled
		end
	end)
end

task.spawn(setupShopPrompt)

print("ShopController loaded!")
