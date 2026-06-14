local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = require(game:GetService("ReplicatedStorage"):WaitForChild("Remotes"))

local UPGRADES = {
	{id="speed1",  cost=50,    label="⚡ Speed I",    desc="+20% Speed"},
	{id="speed2",  cost=200,   label="⚡ Speed II",   desc="+50% Speed"},
	{id="speed3",  cost=600,   label="⚡ Speed III",  desc="+100% Speed"},
	{id="speed4",  cost=2000,  label="⚡ Speed MAX",  desc="+200% Speed"},
	{id="radius1", cost=100,   label="🔵 Radius I",   desc="Bigger auto-collect"},
	{id="radius2", cost=400,   label="🔵 Radius II",  desc="Huge auto-collect"},
	{id="radius3", cost=1500,  label="🔵 Radius MAX", desc="Massive collect"},
	{id="multi2",  cost=300,   label="✨ 2x Coins",   desc="Double all coins"},
	{id="multi3",  cost=1000,  label="✨ 3x Coins",   desc="Triple all coins"},
	{id="multi5",  cost=3000,  label="✨ 5x Coins",   desc="5x all coins"},
	{id="multi10", cost=10000, label="✨ 10x Coins",  desc="10x all coins"},
	{id="magnet1", cost=500,   label="🧲 Magnet I",   desc="Pulls coins from 25 studs"},
	{id="magnet2", cost=2000,  label="🧲 Magnet II",  desc="Pulls from 50 studs"},
	{id="magnet3", cost=8000,  label="🧲 Magnet MAX", desc="Pulls from 100 studs"},
}

local ownedUpgrades = {}
Remotes:Get("CoinsUpdated").OnClientEvent:Connect(function(data)
	if data.upgrades then ownedUpgrades = data.upgrades end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player.PlayerGui

local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0,400,0,540)
shopFrame.Position = UDim2.new(0.5,-200,0.5,-270)
shopFrame.BackgroundColor3 = Color3.fromRGB(15,15,30)
shopFrame.BackgroundTransparency = 0.05
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 5
shopFrame.Parent = gui
Instance.new("UICorner", shopFrame).CornerRadius = UDim.new(0,16)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,54)
titleBar.BackgroundColor3 = Color3.fromRGB(255,180,0)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 6
titleBar.Parent = shopFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,16)
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,-50,1,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🏪 UPGRADE SHOP"
titleLbl.TextColor3 = Color3.fromRGB(0,0,0)
titleLbl.TextScaled = true
titleLbl.Font = Enum.Font.GothamBold
titleLbl.ZIndex = 7
titleLbl.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,38,0,38)
closeBtn.Position = UDim2.new(1,-44,0,8)
closeBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 8
closeBtn.Parent = shopFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)
closeBtn.Activated:Connect(function() shopFrame.Visible = false end)

local msgLabel = Instance.new("TextLabel")
msgLabel.Size = UDim2.new(1,-20,0,32)
msgLabel.Position = UDim2.new(0,10,0,56)
msgLabel.BackgroundTransparency = 1
msgLabel.TextColor3 = Color3.fromRGB(100,255,100)
msgLabel.TextScaled = true
msgLabel.Font = Enum.Font.Gotham
msgLabel.ZIndex = 7
msgLabel.Parent = shopFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1,-16,1,-96)
scrollFrame.Position = UDim2.new(0,8,0,90)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.ZIndex = 6
scrollFrame.Parent = shopFrame
Instance.new("UIListLayout", scrollFrame).Padding = UDim.new(0,7)

local buttons = {}
local function refreshShop()
	scrollFrame.CanvasSize = UDim2.new(0,0,0,#UPGRADES*70)
	for _, b in ipairs(buttons) do b:Destroy() end
	buttons = {}
	for _, upg in ipairs(UPGRADES) do
		local owned = ownedUpgrades[upg.id]
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1,-8,0,62)
		row.BackgroundColor3 = owned and Color3.fromRGB(30,55,30) or Color3.fromRGB(25,25,45)
		row.BorderSizePixel = 0; row.ZIndex = 6; row.Parent = scrollFrame
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)
		table.insert(buttons, row)

		local nl = Instance.new("TextLabel")
		nl.Size=UDim2.new(0.58,0,0.5,0); nl.Position=UDim2.new(0,10,0,4)
		nl.BackgroundTransparency=1; nl.Text=upg.label
		nl.TextColor3=owned and Color3.fromRGB(130,255,130) or Color3.new(1,1,1)
		nl.TextScaled=true; nl.TextXAlignment=Enum.TextXAlignment.Left
		nl.Font=Enum.Font.GothamBold; nl.ZIndex=7; nl.Parent=row

		local dl = Instance.new("TextLabel")
		dl.Size=UDim2.new(0.58,0,0.38,0); dl.Position=UDim2.new(0,10,0.55,0)
		dl.BackgroundTransparency=1; dl.Text=upg.desc
		dl.TextColor3=Color3.fromRGB(160,160,160); dl.TextScaled=true
		dl.TextXAlignment=Enum.TextXAlignment.Left; dl.Font=Enum.Font.Gotham; dl.ZIndex=7; dl.Parent=row

		local btn = Instance.new("TextButton")
		btn.Size=UDim2.new(0.37,0,0.68,0); btn.Position=UDim2.new(0.61,0,0.16,0)
		btn.BackgroundColor3=owned and Color3.fromRGB(70,70,70) or Color3.fromRGB(255,175,0)
		btn.Text=owned and "✓ OWNED" or "🪙 "..upg.cost
		btn.TextColor3=owned and Color3.fromRGB(160,160,160) or Color3.fromRGB(0,0,0)
		btn.TextScaled=true; btn.Font=Enum.Font.GothamBold; btn.ZIndex=7; btn.Parent=row
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

		if not owned then
			btn.Activated:Connect(function()
				local result = Remotes:Get("PurchaseUpgrade"):InvokeServer(upg.id)
				msgLabel.Text = result.message
				if result.success then
					msgLabel.TextColor3 = Color3.fromRGB(100,255,100)
					if result.upgrades then ownedUpgrades = result.upgrades end
					refreshShop()
				else
					msgLabel.TextColor3 = Color3.fromRGB(255,100,100)
				end
			end)
		end
	end
end

local wasNear = false
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local shopPart = workspace:FindFirstChild("ShopPart")
	if not shopPart then return end
	local dist = (shopPart.Position - root.Position).Magnitude
	if dist < 18 and not wasNear then
		wasNear = true; shopFrame.Visible = true; refreshShop()
	elseif dist > 22 and wasNear then
		wasNear = false; shopFrame.Visible = false
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		shopFrame.Visible = not shopFrame.Visible
		if shopFrame.Visible then refreshShop() end
	end
end)
