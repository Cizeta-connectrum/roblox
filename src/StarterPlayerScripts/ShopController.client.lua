-- ShopController.client.lua
-- Handles shop UI and upgrade purchases

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))

local SHOP_OPEN_DISTANCE = 15
local shopOpen = false
local purchasedUpgrades = {}

-- ============================================================
-- Upgrade definitions (mirrors server)
-- ============================================================
local UPGRADES = {
	{ id = "speed1",      label = "Speed I",        cost = 50,   desc = "Walk faster (Speed 20)" },
	{ id = "speed2",      label = "Speed II",       cost = 200,  desc = "Walk faster (Speed 25)" },
	{ id = "speed3",      label = "Speed III",      cost = 500,  desc = "Walk faster (Speed 32)" },
	{ id = "radius1",     label = "Radius I",       cost = 100,  desc = "Collect radius 15 studs" },
	{ id = "radius2",     label = "Radius II",      cost = 400,  desc = "Collect radius 22 studs" },
	{ id = "radius3",     label = "Radius III",     cost = 1000, desc = "Collect radius 35 studs" },
	{ id = "multiplier2", label = "x2 Multiplier",  cost = 300,  desc = "Earn 2x coins" },
	{ id = "multiplier3", label = "x3 Multiplier",  cost = 800,  desc = "Earn 3x coins" },
	{ id = "multiplier5", label = "x5 Multiplier",  cost = 2000, desc = "Earn 5x coins" },
	{ id = "magnet1",     label = "Magnet I",       cost = 500,  desc = "Attract coins (30 studs)" },
	{ id = "magnet2",     label = "Magnet II",      cost = 1500, desc = "Stronger magnet (60 studs)" },
}

-- ============================================================
-- Build Shop ScreenGui
-- ============================================================
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopGui"
shopGui.ResetOnSpawn = false
shopGui.Enabled = false
shopGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
shopGui.Parent = playerGui

-- Background overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.Parent = shopGui

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 480, 0, 580)
panel.Position = UDim2.new(0.5, -240, 0.5, -290)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
panel.BorderSizePixel = 0
panel.Parent = shopGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(255, 200, 0)
panelStroke.Thickness = 2
panelStroke.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 50)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🛒 UPGRADE SHOP"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = panel

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -48, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = panel

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 2)
divider.Position = UDim2.new(0, 10, 0, 58)
divider.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
divider.BorderSizePixel = 0
divider.Parent = panel

-- Message label (success/fail)
local messageLabel = Instance.new("TextLabel")
messageLabel.Size = UDim2.new(1, -20, 0, 28)
messageLabel.Position = UDim2.new(0, 10, 0, 62)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
messageLabel.TextScaled = true
messageLabel.Font = Enum.Font.Gotham
messageLabel.Parent = panel

-- Scroll frame for upgrades
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -104)
scrollFrame.Position = UDim2.new(0, 10, 0, 96)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #UPGRADES * 62)
scrollFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- ============================================================
-- Build upgrade buttons
-- ============================================================
local upgradeButtons = {}

local function showMessage(text, success)
	messageLabel.Text = text
	messageLabel.TextColor3 = success and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 80, 80)
	task.delay(3, function()
		if messageLabel.Text == text then
			messageLabel.Text = ""
		end
	end)
end

for i, upgrade in ipairs(UPGRADES) do
	local row = Instance.new("Frame")
	row.Name = upgrade.id
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	row.BorderSizePixel = 0
	row.LayoutOrder = i
	row.Parent = scrollFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	-- Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 200, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = upgrade.label
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(0, 200, 0.5, -4)
	descLabel.Position = UDim2.new(0, 10, 0.5, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = upgrade.desc
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = row

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Size = UDim2.new(0, 130, 0, 38)
	buyBtn.Position = UDim2.new(1, -140, 0.5, -19)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
	buyBtn.Text = "🪙 " .. tostring(upgrade.cost)
	buyBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
	buyBtn.TextScaled = true
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.BorderSizePixel = 0
	buyBtn.Parent = row

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyBtn

	upgradeButtons[upgrade.id] = buyBtn

	-- Handle purchase
	buyBtn.MouseButton1Click:Connect(function()
		if purchasedUpgrades[upgrade.id] then
			showMessage("Already purchased!", false)
			return
		end

		buyBtn.Text = "..."
		buyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

		local result = RemoteEvents.PurchaseUpgrade:InvokeServer(upgrade.id)

		if result and result.success then
			purchasedUpgrades[upgrade.id] = true
			buyBtn.Text = "✓ Owned"
			buyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			buyBtn.Active = false
			showMessage(result.message, true)
		else
			buyBtn.Text = "🪙 " .. tostring(upgrade.cost)
			buyBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
			showMessage(result and result.message or "Purchase failed.", false)
		end
	end)
end

-- ============================================================
-- Open/Close shop
-- ============================================================
local function openShop()
	shopOpen = true
	shopGui.Enabled = true
	-- Panel pop-in animation
	panel.Size = UDim2.new(0, 0, 0, 0)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 480, 0, 580),
		Position = UDim2.new(0.5, -240, 0.5, -290),
	}):Play()
end

local function closeShop()
	shopOpen = false
	TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}).Completed:Connect(function()
		shopGui.Enabled = false
	end)
	TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
end

closeBtn.MouseButton1Click:Connect(closeShop)

-- Press E near shop part
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E then
		local shopPart = workspace:FindFirstChild("ShopPart")
		if not shopPart then return end

		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local dist = (hrp.Position - shopPart.Position).Magnitude
		if dist <= SHOP_OPEN_DISTANCE then
			if shopOpen then
				closeShop()
			else
				openShop()
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Escape then
		if shopOpen then closeShop() end
	end
end)

-- Show "Press E" prompt when near shop
local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(0, 200, 0, 40)
promptLabel.Position = UDim2.new(0.5, -100, 1, -80)
promptLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
promptLabel.BackgroundTransparency = 0.4
promptLabel.Text = "[E] Open Shop"
promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
promptLabel.TextScaled = true
promptLabel.Font = Enum.Font.GothamBold
promptLabel.BorderSizePixel = 0
promptLabel.Visible = false
promptLabel.Parent = shopGui

local promptCorner = Instance.new("UICorner")
promptCorner.CornerRadius = UDim.new(0, 8)
promptCorner.Parent = promptLabel

-- Always show ShopGui (but shopGui panel toggled)
shopGui.Enabled = true

RunService.Heartbeat:Connect(function()
	local shopPart = workspace:FindFirstChild("ShopPart")
	if not shopPart then
		promptLabel.Visible = false
		return
	end

	local char = player.Character
	if not char then
		promptLabel.Visible = false
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		promptLabel.Visible = false
		return
	end

	local dist = (hrp.Position - shopPart.Position).Magnitude
	promptLabel.Visible = dist <= SHOP_OPEN_DISTANCE and not shopOpen
end)

-- Also close the overlay when not in shop
overlay.Visible = false
overlay.Parent = nil

-- Update: make panel start hidden, use a wrapper frame
panel.Visible = true
