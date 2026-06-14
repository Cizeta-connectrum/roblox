local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local fnGachaSpin = RS:WaitForChild("GachaSpin", 30)
local evCoinsUpdated = RS:WaitForChild("CoinsUpdated", 30)
local gachaMachine = workspace:WaitForChild("GachaMachine", 30)

local currentCoins = 0
evCoinsUpdated.OnClientEvent:Connect(function(data)
	currentCoins = data.coins or 0
end)

local GACHA_TIERS = {
	{id=1, label="🥉 Bronze",   cost=200,   color=Color3.fromRGB(180,110,50),  desc="C70% R28% E2%"},
	{id=2, label="🥈 Silver",   cost=500,   color=Color3.fromRGB(180,180,180), desc="C40% R48% E11% L1%"},
	{id=3, label="🥇 Gold",     cost=1500,  color=Color3.fromRGB(255,200,0),   desc="R48% E36% L6%"},
	{id=4, label="💎 Platinum", cost=5000,  color=Color3.fromRGB(100,200,255), desc="R20% E55% L25%"},
	{id=5, label="🌌 Legend",   cost=20000, color=Color3.fromRGB(200,100,255), desc="E30% L70%"},
}

local ALL_ITEMS = {
	{id="skin_red",      rarity="C", label="🔴 Red Skin"},
	{id="skin_blue",     rarity="C", label="🔵 Blue Skin"},
	{id="skin_yellow",   rarity="C", label="🟡 Yellow Skin"},
	{id="skin_green",    rarity="C", label="🟢 Green Skin"},
	{id="skin_purple",   rarity="C", label="🟣 Purple Skin"},
	{id="trail_star",    rarity="R", label="⭐ Star Trail"},
	{id="trail_fire",    rarity="R", label="🔥 Fire Trail"},
	{id="trail_ice",     rarity="R", label="❄️ Ice Trail"},
	{id="skin_black",    rarity="R", label="⬛ Shadow Skin"},
	{id="skin_white",    rarity="R", label="⬜ Ghost Skin"},
	{id="crown_gold",    rarity="E", label="👑 Gold Crown"},
	{id="crown_diamond", rarity="E", label="💎 Diamond Crown"},
	{id="aura_fire",     rarity="E", label="🔥 Fire Aura"},
	{id="aura_dark",     rarity="E", label="⚫ Dark Aura"},
	{id="aura_rainbow",  rarity="L", label="🌈 Rainbow Aura"},
	{id="aura_galaxy",   rarity="L", label="🌌 Galaxy Aura"},
	{id="trail_galaxy",  rarity="L", label="✨ Galaxy Trail"},
}

local rarityColors = {C=Color3.fromRGB(180,180,180), R=Color3.fromRGB(80,160,255), E=Color3.fromRGB(180,80,255), L=Color3.fromRGB(255,180,0)}
local rarityNames  = {C="⬜ COMMON", R="🔵 RARE", E="🟣 EPIC", L="🌟 LEGENDARY"}

-- GUI setup
local gui = Instance.new("ScreenGui")
gui.Name="GachaGui"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Enabled=false; gui.Parent=player.PlayerGui

local panel = Instance.new("Frame")
panel.Size=UDim2.new(0,440,0,580); panel.Position=UDim2.new(0.5,-220,0.5,-290)
panel.BackgroundColor3=Color3.fromRGB(20,10,35); panel.BackgroundTransparency=0.05
panel.BorderSizePixel=0; panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,16)
local stroke=Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(255,100,200); stroke.Thickness=2; stroke.Parent=panel

-- Header
local header=Instance.new("TextLabel"); header.Size=UDim2.new(1,0,0,54)
header.BackgroundColor3=Color3.fromRGB(80,0,60); header.BackgroundTransparency=0.1
header.BorderSizePixel=0; header.Text="🎰 GACHA"
header.TextColor3=Color3.fromRGB(255,200,100); header.TextScaled=true
header.Font=Enum.Font.GothamBold; header.TextStrokeTransparency=0; header.Parent=panel
Instance.new("UICorner",header).CornerRadius=UDim.new(0,16)

local closeBtn=Instance.new("TextButton"); closeBtn.Size=UDim2.new(0,36,0,36)
closeBtn.Position=UDim2.new(1,-44,0,9); closeBtn.BackgroundColor3=Color3.fromRGB(180,30,60)
closeBtn.Text="✕"; closeBtn.TextColor3=Color3.new(1,1,1); closeBtn.TextScaled=true
closeBtn.Font=Enum.Font.GothamBold; closeBtn.ZIndex=5; closeBtn.Parent=panel
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,8)

-- Coin display
local coinDisplay=Instance.new("TextLabel"); coinDisplay.Size=UDim2.new(1,-20,0,28)
coinDisplay.Position=UDim2.new(0,10,0,58); coinDisplay.BackgroundTransparency=1
coinDisplay.Text="🪙 0"; coinDisplay.TextColor3=Color3.fromRGB(255,215,0)
coinDisplay.TextScaled=true; coinDisplay.Font=Enum.Font.GothamBold
coinDisplay.TextXAlignment=Enum.TextXAlignment.Right; coinDisplay.Parent=panel

evCoinsUpdated.OnClientEvent:Connect(function(data)
	coinDisplay.Text = "🪙 "..math.floor(data.coins or 0)
end)

-- Tier buttons
local tierFrame=Instance.new("Frame"); tierFrame.Size=UDim2.new(1,-20,0,220)
tierFrame.Position=UDim2.new(0,10,0,90); tierFrame.BackgroundTransparency=1; tierFrame.Parent=panel
local tierLayout=Instance.new("UIListLayout"); tierLayout.Padding=UDim.new(0,5); tierLayout.Parent=tierFrame

local tierButtons = {}
for _, tier in ipairs(GACHA_TIERS) do
	local row=Instance.new("TextButton"); row.Size=UDim2.new(1,0,0,38)
	row.BackgroundColor3=tier.color; row.BackgroundTransparency=0.3
	row.BorderSizePixel=0
	row.Text=tier.label.."   🪙"..tier.cost.."   "..tier.desc
	row.TextColor3=Color3.new(1,1,1); row.TextScaled=true
	row.Font=Enum.Font.GothamBold; row.TextStrokeTransparency=0; row.Parent=tierFrame
	Instance.new("UICorner",row).CornerRadius=UDim.new(0,10)
	table.insert(tierButtons, {btn=row, tier=tier})
end

-- Result / roll display
local rollLabel=Instance.new("TextLabel"); rollLabel.Size=UDim2.new(1,-20,0,40)
rollLabel.Position=UDim2.new(0,10,0,320); rollLabel.BackgroundTransparency=1
rollLabel.Text=""; rollLabel.TextColor3=Color3.new(1,1,1)
rollLabel.TextScaled=true; rollLabel.Font=Enum.Font.GothamBold
rollLabel.TextStrokeTransparency=0; rollLabel.Visible=false; rollLabel.Parent=panel

local resultFrame=Instance.new("Frame"); resultFrame.Size=UDim2.new(1,-20,0,70)
resultFrame.Position=UDim2.new(0,10,0,366); resultFrame.BackgroundColor3=Color3.fromRGB(30,15,50)
resultFrame.BackgroundTransparency=0.2; resultFrame.BorderSizePixel=0; resultFrame.Visible=false; resultFrame.Parent=panel
Instance.new("UICorner",resultFrame).CornerRadius=UDim.new(0,10)
local resultLabel=Instance.new("TextLabel"); resultLabel.Size=UDim2.new(1,-10,1,0)
resultLabel.Position=UDim2.new(0,5,0,0); resultLabel.BackgroundTransparency=1
resultLabel.Text=""; resultLabel.TextColor3=Color3.fromRGB(255,220,100)
resultLabel.TextScaled=true; resultLabel.Font=Enum.Font.GothamBold
resultLabel.TextStrokeTransparency=0; resultLabel.TextWrapped=true; resultLabel.Parent=resultFrame

-- Owned items scroll
local ownedTitle=Instance.new("TextLabel"); ownedTitle.Size=UDim2.new(1,-20,0,24)
ownedTitle.Position=UDim2.new(0,10,0,442); ownedTitle.BackgroundTransparency=1
ownedTitle.Text="📦 Owned: 0/17"; ownedTitle.TextColor3=Color3.fromRGB(200,200,255)
ownedTitle.TextScaled=true; ownedTitle.Font=Enum.Font.GothamBold
ownedTitle.TextXAlignment=Enum.TextXAlignment.Left; ownedTitle.Parent=panel

local itemsScroll=Instance.new("ScrollingFrame"); itemsScroll.Size=UDim2.new(1,-20,0,106)
itemsScroll.Position=UDim2.new(0,10,0,468); itemsScroll.BackgroundColor3=Color3.fromRGB(10,5,20)
itemsScroll.BackgroundTransparency=0.3; itemsScroll.BorderSizePixel=0
itemsScroll.ScrollBarThickness=4; itemsScroll.ScrollBarImageColor3=Color3.fromRGB(255,100,200)
itemsScroll.CanvasSize=UDim2.new(0,0,0,0); itemsScroll.Parent=panel
Instance.new("UICorner",itemsScroll).CornerRadius=UDim.new(0,8)
local itemsLayout=Instance.new("UIListLayout"); itemsLayout.Padding=UDim.new(0,3)
itemsLayout.FillDirection=Enum.FillDirection.Horizontal; itemsLayout.Wraps=true; itemsLayout.Parent=itemsScroll
local ip=Instance.new("UIPadding"); ip.PaddingLeft=UDim.new(0,5); ip.PaddingTop=UDim.new(0,5); ip.Parent=itemsScroll

local itemChips = {}
local function buildItemChips(gachaItems)
	for _, c in pairs(itemChips) do c:Destroy() end; itemChips={}
	local owned=0
	for _, item in ipairs(ALL_ITEMS) do
		local have = gachaItems and gachaItems[item.id]
		if have then owned=owned+1 end
		local chip=Instance.new("TextLabel"); chip.Size=UDim2.new(0,120,0,24)
		chip.BackgroundColor3=have and rarityColors[item.rarity] or Color3.fromRGB(40,40,40)
		chip.BackgroundTransparency=have and 0.4 or 0.7
		chip.BorderSizePixel=0; chip.Text=(have and "" or "🔒")..item.label
		chip.TextColor3=have and Color3.new(1,1,1) or Color3.fromRGB(80,80,80)
		chip.TextScaled=true; chip.Font=Enum.Font.Gotham; chip.Parent=itemsScroll
		Instance.new("UICorner",chip).CornerRadius=UDim.new(0,5)
		table.insert(itemChips,chip)
	end
	itemsScroll.CanvasSize=UDim2.new(0,0,0,math.ceil(#ALL_ITEMS/4)*29+10)
	ownedTitle.Text="📦 Owned: "..owned.."/"..#ALL_ITEMS
end
buildItemChips({})

-- Open/close
local isOpen=false; local isSpinning=false
local function openPanel()
	if isOpen then return end; isOpen=true; gui.Enabled=true
	panel.Size=UDim2.new(0,0,0,0); panel.Position=UDim2.new(0.5,0,0.5,0)
	TweenService:Create(panel,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
		Size=UDim2.new(0,440,0,580),Position=UDim2.new(0.5,-220,0.5,-290)}):Play()
end
local function closePanel()
	if not isOpen or isSpinning then return end; isOpen=false
	TweenService:Create(panel,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
		Size=UDim2.new(0,0,0,0),Position=UDim2.new(0.5,0,0.5,0)}):Play()
	task.delay(0.2,function() gui.Enabled=false end)
end
closeBtn.MouseButton1Click:Connect(closePanel)

-- Spin animation
local raritySeq={"C","C","R","C","R","E","C","R","L","C","R","E"}
local function doSpin(tier, callback)
	isSpinning=true; rollLabel.Visible=true; resultFrame.Visible=false
	-- Disable all tier buttons
	for _,tb in ipairs(tierButtons) do tb.btn.Active=false; tb.btn.BackgroundTransparency=0.7 end
	local i=0; local spinCount=18
	local function nextFrame()
		i=i+1
		local r=raritySeq[(i%#raritySeq)+1]
		rollLabel.Text=rarityNames[r]; rollLabel.TextColor3=rarityColors[r]
		if i>=spinCount then task.delay(0.3,callback)
		else
			local slow=(i>spinCount-5) and (1+(i-(spinCount-5))*0.5) or 1
			task.delay(0.07*slow,nextFrame)
		end
	end
	nextFrame()
end

-- Connect tier buttons
for _,tb in ipairs(tierButtons) do
	tb.btn.MouseButton1Click:Connect(function()
		if isSpinning then return end
		local tier=tb.tier
		doSpin(tier, function()
			local result=fnGachaSpin:InvokeServer(tier.id)
			rollLabel.Visible=false; resultFrame.Visible=true
			if result and result.success then
				local item=result.item
				local rarity=item and item.rarity or "C"
				local color=rarityColors[rarity] or Color3.new(1,1,1)
				local dupNote=result.alreadyOwned and " ♻️+10% refund" or " NEW!"
				resultLabel.Text="🎉 ["..rarityNames[rarity].."] "..(item and item.label or "?")..dupNote
				resultLabel.TextColor3=color
				resultFrame.BackgroundColor3=color; resultFrame.BackgroundTransparency=0.6
				TweenService:Create(resultFrame,TweenInfo.new(0.1),{BackgroundTransparency=0.1}):Play()
				task.delay(0.15,function()
					TweenService:Create(resultFrame,TweenInfo.new(0.4),{BackgroundTransparency=0.6}):Play()
				end)
				if result.gachaItems then buildItemChips(result.gachaItems) end
			else
				resultLabel.Text="❌ "..(result and result.message or "Spin failed!")
				resultLabel.TextColor3=Color3.fromRGB(255,80,80)
				resultFrame.BackgroundColor3=Color3.fromRGB(100,20,20); resultFrame.BackgroundTransparency=0.3
			end
			isSpinning=false
			for _,tb2 in ipairs(tierButtons) do tb2.btn.Active=true; tb2.btn.BackgroundTransparency=0.3 end
		end)
	end)
end

-- Proximity check
RunService.Heartbeat:Connect(function()
	if isSpinning then return end
	local char=player.Character; if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
	if not gachaMachine or not gachaMachine.Parent then return end
	local dist=(root.Position-gachaMachine.Position).Magnitude
	if dist<=10 and not isOpen then openPanel()
	elseif dist>12 and isOpen then closePanel() end
end)

UserInputService.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if input.KeyCode==Enum.KeyCode.G then
		if isOpen then closePanel() else openPanel() end
	end
end)

print("GachaController loaded!")
