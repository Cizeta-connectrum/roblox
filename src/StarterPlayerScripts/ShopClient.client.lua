local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Remotes"))

local UPGRADES = {
    {id="speed1",  cost=50,    label="⚡ Speed I",     desc="+20% Speed"},
    {id="speed2",  cost=200,   label="⚡ Speed II",    desc="+50% Speed"},
    {id="speed3",  cost=600,   label="⚡ Speed III",   desc="+100% Speed"},
    {id="speed4",  cost=2000,  label="⚡ Speed MAX",   desc="+200% Speed"},
    {id="radius1", cost=100,   label="🔵 Radius I",    desc="Bigger auto-collect"},
    {id="radius2", cost=400,   label="🔵 Radius II",   desc="Huge auto-collect"},
    {id="radius3", cost=1500,  label="🔵 Radius MAX",  desc="Massive collect"},
    {id="multi2",  cost=300,   label="✨ 2x Coins",    desc="Double all coins"},
    {id="multi3",  cost=1000,  label="✨ 3x Coins",    desc="Triple all coins"},
    {id="multi5",  cost=3000,  label="✨ 5x Coins",    desc="5x all coins"},
    {id="multi10", cost=10000, label="✨ 10x Coins",   desc="10x all coins"},
    {id="magnet1", cost=500,   label="🧲 Magnet I",    desc="Pulls coins from 25 studs"},
    {id="magnet2", cost=2000,  label="🧲 Magnet II",   desc="Pulls from 50 studs"},
    {id="magnet3", cost=8000,  label="🧲 Magnet MAX",  desc="Pulls from 100 studs"},
    {id="lucky1",  cost=800,   label="🍀 Lucky I",     desc="+10% lucky coins"},
    {id="lucky2",  cost=3000,  label="🍀 Lucky II",    desc="+25% lucky coins"},
}

local ownedUpgrades = {}
local currentCoins = 0

Remotes:Get("CoinsUpdated").OnClientEvent:Connect(function(data)
    currentCoins = data.coins
    if data.upgrades then ownedUpgrades = data.upgrades end
end)

-- Shop GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 420, 0, 560)
shopFrame.Position = UDim2.new(0.5, -210, 0.5, -280)
shopFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
shopFrame.BackgroundTransparency = 0.05
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 5
shopFrame.Parent = screenGui
Instance.new("UICorner", shopFrame).CornerRadius = UDim.new(0, 16)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 55)
titleLabel.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
titleLabel.BackgroundTransparency = 0
titleLabel.Text = "🏪 UPGRADE SHOP"
titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.ZIndex = 6
titleLabel.Parent = shopFrame
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 16)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 7
closeBtn.Parent = shopFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.Activated:Connect(function() shopFrame.Visible = false end)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -65)
scrollFrame.Position = UDim2.new(0, 10, 0, 60)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ZIndex = 6
scrollFrame.Parent = shopFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = scrollFrame

local msgLabel = Instance.new("TextLabel")
msgLabel.Size = UDim2.new(1, -20, 0, 35)
msgLabel.Position = UDim2.new(0, 10, 0, 58)
msgLabel.BackgroundTransparency = 1
msgLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
msgLabel.TextScaled = true
msgLabel.Font = Enum.Font.Gotham
msgLabel.ZIndex = 7
msgLabel.Parent = shopFrame

local buttons = {}

local function refreshShop()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #UPGRADES * 72)
    for _, btn in ipairs(buttons) do btn:Destroy() end
    buttons = {}
    
    for _, upgrade in ipairs(UPGRADES) do
        local owned = ownedUpgrades[upgrade.id]
        
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 64)
        row.BackgroundColor3 = owned and Color3.fromRGB(40, 60, 40) or Color3.fromRGB(30, 30, 50)
        row.BorderSizePixel = 0
        row.ZIndex = 6
        row.Parent = scrollFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
        table.insert(buttons, row)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = upgrade.label
        nameLabel.TextColor3 = owned and Color3.fromRGB(150,255,150) or Color3.fromRGB(255,255,255)
        nameLabel.TextScaled = true
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.ZIndex = 7
        nameLabel.Parent = row
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.6, 0, 0.4, 0)
        descLabel.Position = UDim2.new(0, 10, 0.55, 0)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = upgrade.desc
        descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        descLabel.TextScaled = true
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Font = Enum.Font.Gotham
        descLabel.ZIndex = 7
        descLabel.Parent = row
        
        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0.35, 0, 0.7, 0)
        buyBtn.Position = UDim2.new(0.63, 0, 0.15, 0)
        buyBtn.BackgroundColor3 = owned and Color3.fromRGB(80,80,80) or Color3.fromRGB(255, 180, 0)
        buyBtn.Text = owned and "✓ OWNED" or "🪙 "..upgrade.cost
        buyBtn.TextColor3 = owned and Color3.fromRGB(180,180,180) or Color3.fromRGB(0,0,0)
        buyBtn.TextScaled = true
        buyBtn.Font = Enum.Font.GothamBold
        buyBtn.ZIndex = 7
        buyBtn.Parent = row
        Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
        
        if not owned then
            buyBtn.Activated:Connect(function()
                local result = Remotes:Get("PurchaseUpgrade"):InvokeServer(upgrade.id)
                msgLabel.Text = result.message
                if result.success then
                    msgLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    if result.upgrades then ownedUpgrades = result.upgrades end
                    refreshShop()
                else
                    msgLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                end
            end)
        end
    end
end

-- Open shop when near ShopPart or press Tab
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.E then
        -- check if near shop
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local shopPart = workspace:FindFirstChild("ShopPart")
        if shopPart and (shopPart.Position - root.Position).Magnitude < 20 then
            shopFrame.Visible = not shopFrame.Visible
            if shopFrame.Visible then refreshShop() end
        elseif input.KeyCode == Enum.KeyCode.Tab then
            shopFrame.Visible = not shopFrame.Visible
            if shopFrame.Visible then refreshShop() end
        end
    end
end)

-- Also open shop automatically when walking into ShopPart
game:GetService("RunService").Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local shopPart = workspace:FindFirstChild("ShopPart")
    if shopPart and (shopPart.Position - root.Position).Magnitude < 15 then
        if not shopFrame.Visible then
            shopFrame.Visible = true
            refreshShop()
        end
    else
        if shopFrame.Visible then
            -- only auto-close if we moved away
            if shopPart and (shopPart.Position - root.Position).Magnitude > 20 then
                shopFrame.Visible = false
            end
        end
    end
end)
