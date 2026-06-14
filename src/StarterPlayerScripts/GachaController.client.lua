local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local fnGachaSpin = RS:WaitForChild("GachaSpin", 30)

-- Wait for character and workspace
local gachaMachine = workspace:WaitForChild("GachaMachine", 30)

local gui = Instance.new("ScreenGui")
gui.Name = "GachaGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = player.PlayerGui

-- ===== MAIN PANEL =====
local panel = Instance.new("Frame")
panel.Name = "GachaPanel"
panel.Size = UDim2.new(0, 400, 0, 520)
panel.Position = UDim2.new(0.5, -200, 0.5, -260)
panel.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

-- Gradient stroke
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 100, 200)
stroke.Thickness = 2
stroke.Parent = panel

-- Header
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 60)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(80, 0, 60)
header.BackgroundTransparency = 0.1
header.BorderSizePixel = 0
header.Text = "🎰 GACHA - 200 coins/spin"
header.TextColor3 = Color3.fromRGB(255, 200, 100)
header.TextScaled = true
header.Font = Enum.Font.GothamBold
header.TextStrokeTransparency = 0
header.Parent = panel
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 16); c.Parent = header
end

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 60)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 5
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Items section label
local itemsTitle = Instance.new("TextLabel")
itemsTitle.Size = UDim2.new(1, -20, 0, 28)
itemsTitle.Position = UDim2.new(0, 10, 0, 66)
itemsTitle.BackgroundTransparency = 1
itemsTitle.Text = "📦 Your Items:"
itemsTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
itemsTitle.TextScaled = true
itemsTitle.Font = Enum.Font.GothamBold
itemsTitle.TextXAlignment = Enum.TextXAlignment.Left
itemsTitle.Parent = panel

-- Scrolling items list
local itemsScroll = Instance.new("ScrollingFrame")
itemsScroll.Size = UDim2.new(1, -20, 0, 200)
itemsScroll.Position = UDim2.new(0, 10, 0, 96)
itemsScroll.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
itemsScroll.BackgroundTransparency = 0.3
itemsScroll.BorderSizePixel = 0
itemsScroll.ScrollBarThickness = 4
itemsScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 100, 200)
itemsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
itemsScroll.Parent = panel
Instance.new("UICorner", itemsScroll).CornerRadius = UDim.new(0, 8)

local itemsLayout = Instance.new("UIListLayout")
itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
itemsLayout.Padding = UDim.new(0, 4)
itemsLayout.Parent = itemsScroll

local itemsPadding = Instance.new("UIPadding")
itemsPadding.PaddingLeft = UDim.new(0, 6)
itemsPadding.PaddingTop = UDim.new(0, 6)
itemsPadding.Parent = itemsScroll

-- Result display area
local resultFrame = Instance.new("Frame")
resultFrame.Size = UDim2.new(1, -20, 0, 80)
resultFrame.Position = UDim2.new(0, 10, 0, 306)
resultFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 50)
resultFrame.BackgroundTransparency = 0.2
resultFrame.BorderSizePixel = 0
resultFrame.Visible = false
resultFrame.Parent = panel
Instance.new("UICorner", resultFrame).CornerRadius = UDim.new(0, 10)

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, -10, 1, 0)
resultLabel.Position = UDim2.new(0, 5, 0, 0)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
resultLabel.TextScaled = true
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextStrokeTransparency = 0
resultLabel.TextWrapped = true
resultLabel.Parent = resultFrame

-- Rarity roll animation label
local rollLabel = Instance.new("TextLabel")
rollLabel.Size = UDim2.new(1, -20, 0, 50)
rollLabel.Position = UDim2.new(0, 10, 0, 396)
rollLabel.BackgroundTransparency = 1
rollLabel.Text = ""
rollLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rollLabel.TextScaled = true
rollLabel.Font = Enum.Font.GothamBold
rollLabel.TextStrokeTransparency = 0
rollLabel.Visible = false
rollLabel.Parent = panel

-- SPIN button
local spinBtn = Instance.new("TextButton")
spinBtn.Size = UDim2.new(1, -40, 0, 56)
spinBtn.Position = UDim2.new(0, 20, 0, 454)
spinBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 150)
spinBtn.BorderSizePixel = 0
spinBtn.Text = "🎰 SPIN (200 🪙)"
spinBtn.TextColor3 = Color3.new(1, 1, 1)
spinBtn.TextScaled = true
spinBtn.Font = Enum.Font.GothamBold
spinBtn.TextStrokeTransparency = 0
spinBtn.Parent = panel
Instance.new("UICorner", spinBtn).CornerRadius = UDim.new(0, 12)

-- ===== RARITY COLORS =====
local rarityColors = {
	C = Color3.fromRGB(180, 180, 180),
	R = Color3.fromRGB(80, 160, 255),
	E = Color3.fromRGB(180, 80, 255),
	L = Color3.fromRGB(255, 180, 0),
}
local rarityNames = {
	C = "⬜ COMMON",
	R = "🔵 RARE",
	E = "🟣 EPIC",
	L = "🌟 LEGENDARY",
}

-- ===== ITEM ROWS =====
local ownedItemRows = {}

local GACHA_ITEMS_ORDER = {
	{id="skin_red",     rarity="C", label="🔴 Red Skin"},
	{id="skin_blue",    rarity="C", label="🔵 Blue Skin"},
	{id="skin_yellow",  rarity="C", label="🟡 Yellow Skin"},
	{id="trail_star",   rarity="R", label="⭐ Star Trail"},
	{id="trail_fire",   rarity="R", label="🔥 Fire Trail"},
	{id="crown_gold",   rarity="E", label="👑 Gold Crown"},
	{id="aura_rainbow", rarity="L", label="🌈 Rainbow Aura"},
}

local function buildItemList(gachaItems)
	-- Clear existing rows
	for _, row in pairs(ownedItemRows) do
		row:Destroy()
	end
	ownedItemRows = {}

	local ownedCount = 0
	for _, item in ipairs(GACHA_ITEMS_ORDER) do
		local owned = gachaItems and gachaItems[item.id]
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 28)
		row.BackgroundColor3 = owned and Color3.fromRGB(40, 20, 60) or Color3.fromRGB(15, 8, 25)
		row.BackgroundTransparency = owned and 0.3 or 0.6
		row.BorderSizePixel = 0
		row.LayoutOrder = owned and 0 or 1
		row.Parent = itemsScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		local rowLabel = Instance.new("TextLabel")
		rowLabel.Size = UDim2.new(1, -8, 1, 0)
		rowLabel.Position = UDim2.new(0, 4, 0, 0)
		rowLabel.BackgroundTransparency = 1
		rowLabel.Text = (owned and "✅ " or "🔒 ") .. item.label .. " [" .. item.rarity .. "]"
		rowLabel.TextColor3 = owned and (rarityColors[item.rarity] or Color3.new(1,1,1)) or Color3.fromRGB(80,80,80)
		rowLabel.TextScaled = true
		rowLabel.Font = Enum.Font.Gotham
		rowLabel.TextXAlignment = Enum.TextXAlignment.Left
		rowLabel.Parent = row

		table.insert(ownedItemRows, row)
		if owned then ownedCount = ownedCount + 1 end
	end

	-- Update canvas size
	itemsScroll.CanvasSize = UDim2.new(0, 0, 0, #GACHA_ITEMS_ORDER * 32 + 10)

	-- Update title
	itemsTitle.Text = "📦 Your Items (" .. ownedCount .. "/" .. #GACHA_ITEMS_ORDER .. "):"
end

-- Build initial empty list
buildItemList({})

-- ===== OPEN/CLOSE LOGIC =====
local isOpen = false
local isSpinning = false

local function openPanel()
	if isOpen then return end
	isOpen = true
	gui.Enabled = true
	panel.Size = UDim2.new(0, 0, 0, 0)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 520),
		Position = UDim2.new(0.5, -200, 0.5, -260),
	}):Play()
end

local function closePanel()
	if not isOpen then return end
	isOpen = false
	TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()
	task.delay(0.2, function()
		gui.Enabled = false
	end)
end

closeBtn.MouseButton1Click:Connect(closePanel)

-- ===== SPIN ANIMATION =====
local raritySequence = {"C","C","R","C","R","E","C","R","L","C","R","E"}

local function doSpinAnimation(callback)
	isSpinning = true
	spinBtn.Text = "⏳ Spinning..."
	spinBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 80)
	rollLabel.Visible = true
	resultFrame.Visible = false

	local spinCount = 16
	local delay = 0.06
	local i = 0

	local function nextFrame()
		i = i + 1
		local rarity = raritySequence[(i % #raritySequence) + 1]
		rollLabel.Text = rarityNames[rarity]
		rollLabel.TextColor3 = rarityColors[rarity]

		if i >= spinCount then
			task.delay(0.3, callback)
		else
			-- Slow down near the end
			local slowFactor = (i > spinCount - 4) and (1 + (i - (spinCount-4)) * 0.4) or 1
			task.delay(delay * slowFactor, nextFrame)
		end
	end
	nextFrame()
end

-- ===== SPIN BUTTON =====
spinBtn.MouseButton1Click:Connect(function()
	if isSpinning then return end

	doSpinAnimation(function()
		-- Call server
		local result = fnGachaSpin:InvokeServer()

		rollLabel.Visible = false
		resultFrame.Visible = true

		if result and result.success then
			local item = result.item
			local rarity = item and item.rarity or "C"
			local color = rarityColors[rarity] or Color3.new(1,1,1)

			resultLabel.Text = "🎉 " .. (result.message or "Got item!")
			resultLabel.TextColor3 = color
			resultFrame.BackgroundColor3 = color
			resultFrame.BackgroundTransparency = 0.6

			-- Flash effect
			TweenService:Create(resultFrame, TweenInfo.new(0.1), {BackgroundTransparency = 0.1}):Play()
			task.delay(0.15, function()
				TweenService:Create(resultFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0.6}):Play()
			end)

			-- Rebuild item list
			if result.gachaItems then
				buildItemList(result.gachaItems)
			end
		else
			resultLabel.Text = "❌ " .. (result and result.message or "Spin failed!")
			resultLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			resultFrame.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
			resultFrame.BackgroundTransparency = 0.3
		end

		isSpinning = false
		spinBtn.Text = "🎰 SPIN (200 🪙)"
		spinBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 150)
	end)
end)

-- ===== PROXIMITY CHECK (within 10 studs) =====
RunService.Heartbeat:Connect(function()
	if isSpinning then return end
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if not gachaMachine or not gachaMachine.Parent then return end
	local dist = (root.Position - gachaMachine.Position).Magnitude
	if dist <= 10 and not isOpen then
		openPanel()
	elseif dist > 12 and isOpen and not isSpinning then
		closePanel()
	end
end)

-- ===== G KEY TOGGLE =====
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.G then
		if isOpen then
			closePanel()
		else
			openPanel()
		end
	end
end)

print("GachaController loaded!")
