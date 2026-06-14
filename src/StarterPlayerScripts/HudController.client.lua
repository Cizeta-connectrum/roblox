local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Get RemoteEvents directly
local evCoinsUpdated = RS:WaitForChild("CoinsUpdated", 30)
local evShowEffect   = RS:WaitForChild("ShowEffect",   30)
local evAnnounce     = RS:WaitForChild("EventAnnounce",30)

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.Parent = player.PlayerGui

-- Coin counter
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(0,280,0,65)
coinFrame.Position = UDim2.new(0.5,-140,0,10)
coinFrame.BackgroundColor3 = Color3.fromRGB(0,0,0)
coinFrame.BackgroundTransparency = 0.35
coinFrame.BorderSizePixel = 0
coinFrame.Parent = gui
Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(0,14)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1,0,1,0); coinLabel.BackgroundTransparency=1
coinLabel.Text="🪙 0"; coinLabel.TextColor3=Color3.fromRGB(255,215,0)
coinLabel.TextScaled=true; coinLabel.Font=Enum.Font.GothamBold
coinLabel.Parent = coinFrame

-- Speed indicator
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0,180,0,30)
speedLabel.Position = UDim2.new(0.5,-90,0,78)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "🏃 Speed: 16"
speedLabel.TextColor3 = Color3.fromRGB(200,200,200)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = gui

-- Combo
local comboFrame = Instance.new("Frame")
comboFrame.Size = UDim2.new(0,230,0,44)
comboFrame.Position = UDim2.new(0.5,-115,0,112)
comboFrame.BackgroundColor3 = Color3.fromRGB(255,80,0)
comboFrame.BackgroundTransparency = 1
comboFrame.BorderSizePixel = 0
comboFrame.Parent = gui
Instance.new("UICorner", comboFrame).CornerRadius = UDim.new(0,10)
local comboLabel = Instance.new("TextLabel")
comboLabel.Size=UDim2.new(1,0,1,0); comboLabel.BackgroundTransparency=1
comboLabel.TextColor3=Color3.fromRGB(255,150,0); comboLabel.TextScaled=true
comboLabel.Font=Enum.Font.GothamBold; comboLabel.Parent=comboFrame

-- Badges
local function makeBadge(color, yOff, text)
	local f = Instance.new("Frame")
	f.Size=UDim2.new(0,165,0,44); f.Position=UDim2.new(1,-172,0,yOff)
	f.BackgroundColor3=color; f.BackgroundTransparency=0.25
	f.BorderSizePixel=0; f.Visible=false; f.Parent=gui
	Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)
	local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=Color3.new(1,1,1)
	lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.Parent=f
	return f, lbl
end
local multFrame, multLabel = makeBadge(Color3.fromRGB(0,180,0), 10, "✨ x1 COINS")
local magnetFrame = makeBadge(Color3.fromRGB(100,0,200), 62, "🧲 MAGNET")

-- Event banner
local bannerFrame = Instance.new("Frame")
bannerFrame.Size=UDim2.new(0,460,0,55); bannerFrame.Position=UDim2.new(0.5,-230,0.15,0)
bannerFrame.BackgroundColor3=Color3.fromRGB(220,50,50); bannerFrame.BackgroundTransparency=0.15
bannerFrame.BorderSizePixel=0; bannerFrame.Visible=false; bannerFrame.Parent=gui
Instance.new("UICorner",bannerFrame).CornerRadius=UDim.new(0,12)
local bannerLabel=Instance.new("TextLabel"); bannerLabel.Size=UDim2.new(1,0,1,0)
bannerLabel.BackgroundTransparency=1; bannerLabel.TextColor3=Color3.new(1,1,1)
bannerLabel.TextScaled=true; bannerLabel.Font=Enum.Font.GothamBold; bannerLabel.Parent=bannerFrame

-- Hint
local hintLabel = Instance.new("TextLabel")
hintLabel.Size=UDim2.new(0,520,0,32); hintLabel.Position=UDim2.new(0.5,-260,1,-44)
hintLabel.BackgroundTransparency=1
hintLabel.Text="🏪 Walk to SHOP | ⚡ Yellow=BOOST | 🐌 Purple=SLOW | 💸 Red=TAX | 🕳️ Black=HOLE"
hintLabel.TextColor3=Color3.fromRGB(200,200,200); hintLabel.TextScaled=true
hintLabel.Font=Enum.Font.Gotham; hintLabel.Parent=gui
task.delay(12, function()
	TweenService:Create(hintLabel,TweenInfo.new(2),{TextTransparency=1}):Play()
end)

-- Updates
evCoinsUpdated.OnClientEvent:Connect(function(data)
	local c = data.coins
	local fmt
	if c>=1e6 then fmt=string.format("%.1fM",c/1e6)
	elseif c>=1000 then fmt=string.format("%.1fK",c/1000)
	else fmt=tostring(math.floor(c)) end
	coinLabel.Text = "🪙 "..fmt

	if data.speed then
		speedLabel.Text = "🏃 Speed: "..math.floor(data.speed)
	end

	TweenService:Create(coinFrame,TweenInfo.new(0.07),{Size=UDim2.new(0,310,0,72)}):Play()
	task.delay(0.07,function()
		TweenService:Create(coinFrame,TweenInfo.new(0.12),{Size=UDim2.new(0,280,0,65)}):Play()
	end)

	if data.combo and data.combo >= 10 then
		comboFrame.BackgroundTransparency = 0.25
		local s = data.comboMultiplier>1 and (" x"..data.comboMultiplier.."!") or ""
		comboLabel.Text = "🔥 COMBO "..data.combo..s
	else
		comboFrame.BackgroundTransparency = 1; comboLabel.Text = ""
	end

	if data.multiplier and data.multiplier > 1 then
		multFrame.Visible=true; multLabel.Text="✨ x"..data.multiplier.." COINS"
	end
	if data.magnetRadius and data.magnetRadius > 0 then
		magnetFrame.Visible = true
	end
end)

-- Floating text
evShowEffect.OnClientEvent:Connect(function(data)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local screenPos, onScreen = camera:WorldToScreenPoint(data.position + Vector3.new(0,3,0))
	if not onScreen then return end
	local lbl = Instance.new("TextLabel")
	lbl.Size=UDim2.new(0,120,0,46); lbl.Position=UDim2.new(0,screenPos.X-60,0,screenPos.Y-23)
	lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold
	lbl.TextScaled=true; lbl.ZIndex=10
	if data.type=="lucky" then
		lbl.Text="⭐ +"..data.value.." LUCKY!"; lbl.TextColor3=Color3.fromRGB(255,255,0)
		lbl.TextStrokeTransparency=0; lbl.TextStrokeColor3=Color3.fromRGB(180,80,0)
	elseif data.type=="tax" then
		lbl.Text="💸 "..data.value; lbl.TextColor3=Color3.fromRGB(255,80,80)
		lbl.TextStrokeTransparency=0
	elseif data.combo and data.combo>=20 then
		lbl.Text="🔥 +"..data.value; lbl.TextColor3=Color3.fromRGB(255,100,0)
		lbl.TextStrokeTransparency=0
	else
		lbl.Text="+"..data.value; lbl.TextColor3=Color3.new(1,1,1)
		lbl.TextStrokeTransparency=0.4
	end
	lbl.Parent=gui
	TweenService:Create(lbl,TweenInfo.new(0.75,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
		Position=UDim2.new(0,screenPos.X-60,0,screenPos.Y-110),
		TextTransparency=1, TextStrokeTransparency=1,
	}):Play()
	game:GetService("Debris"):AddItem(lbl, 0.8)
end)

-- Banner
evAnnounce.OnClientEvent:Connect(function(msg)
	bannerLabel.Text=msg; bannerFrame.Visible=true
	bannerLabel.TextTransparency=0; bannerFrame.BackgroundTransparency=0.1
	task.delay(0.1,function()
		TweenService:Create(bannerFrame,TweenInfo.new(2.5),{BackgroundTransparency=1}):Play()
		TweenService:Create(bannerLabel,TweenInfo.new(2.5),{TextTransparency=1}):Play()
	end)
	task.delay(3,function()
		bannerFrame.Visible=false; bannerLabel.TextTransparency=0
	end)
end)
