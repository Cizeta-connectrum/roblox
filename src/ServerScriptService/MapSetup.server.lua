local TweenService = game:GetService("TweenService")

local existingBaseplate = workspace:FindFirstChild("Baseplate")
if existingBaseplate then existingBaseplate:Destroy() end

local baseplate = Instance.new("Part")
baseplate.Name = "Baseplate"
baseplate.Size = Vector3.new(500, 1, 500)
baseplate.Position = Vector3.new(0, -0.5, 0)
baseplate.Anchored = true; baseplate.Locked = true
baseplate.Color = Color3.fromRGB(106, 127, 63)
baseplate.Material = Enum.Material.Grass
baseplate.Parent = workspace

local function makeBillboard(parent, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0,160,0,55)
	bb.StudsOffset = Vector3.new(0,4,0)
	bb.AlwaysOnTop = true
	bb.Parent = parent
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundColor3 = Color3.fromRGB(0,0,0)
	lbl.BackgroundTransparency = 0.35
	lbl.Text = text
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = bb
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,8)
end

-- ⚡ Boost pads
for _, pos in ipairs({
	Vector3.new(60,0.5,60), Vector3.new(-60,0.5,60),
	Vector3.new(60,0.5,-60), Vector3.new(-60,0.5,-60),
	Vector3.new(100,0.5,0),
}) do
	local p = Instance.new("Part")
	p.Name = "BoostPad"
	p.Size = Vector3.new(10,0.6,10)
	p.Position = pos
	p.Anchored = true; p.CanCollide = true
	p.Color = Color3.fromRGB(255,220,0)
	p.Material = Enum.Material.Neon
	p.Parent = workspace
	makeBillboard(p, "⚡ BOOST! +Speed", Color3.fromRGB(255,255,0))
	local pl = Instance.new("PointLight"); pl.Brightness=2; pl.Range=14; pl.Color=Color3.fromRGB(255,220,0); pl.Parent=p
end

-- 🐌 Slow zones
for _, pos in ipairs({
	Vector3.new(30,0.3,100), Vector3.new(-80,0.3,-30), Vector3.new(120,0.3,-80),
}) do
	local p = Instance.new("Part")
	p.Name = "SlowZone"
	p.Size = Vector3.new(16,0.4,16)
	p.Position = pos
	p.Anchored = true; p.CanCollide = true
	p.Color = Color3.fromRGB(80,0,160)
	p.Material = Enum.Material.Neon
	p.Transparency = 0.2
	p.Parent = workspace
	makeBillboard(p, "🐌 SLOW ZONE!", Color3.fromRGB(200,100,255))
	local pl = Instance.new("PointLight"); pl.Brightness=2; pl.Range=14; pl.Color=Color3.fromRGB(80,0,160); pl.Parent=p
end

-- 💸 Tax zones (マイナス: コインを20%失う)
for _, pos in ipairs({
	Vector3.new(-40,0.3,-100), Vector3.new(150,0.3,50),
}) do
	local p = Instance.new("Part")
	p.Name = "TaxZone"
	p.Size = Vector3.new(14,0.4,14)
	p.Position = pos
	p.Anchored = true; p.CanCollide = true
	p.Color = Color3.fromRGB(200,30,30)
	p.Material = Enum.Material.Neon
	p.Transparency = 0.2
	p.Parent = workspace
	makeBillboard(p, "💸 TAX! -20% Coins", Color3.fromRGB(255,80,80))
	local pl = Instance.new("PointLight"); pl.Brightness=2; pl.Range=14; pl.Color=Color3.fromRGB(200,30,30); pl.Parent=p
end

-- 🕳️ Holes (マイナス: 近づくとコイン-30%+飛ばされる)
for _, pos in ipairs({
	Vector3.new(-100,-0.4,50), Vector3.new(80,-0.4,-120),
}) do
	local hole = Instance.new("Part")
	hole.Name = "Hole"
	hole.Shape = Enum.PartType.Cylinder
	hole.Size = Vector3.new(0.5,14,14)
	hole.CFrame = CFrame.new(pos) * CFrame.Angles(0,0,math.pi/2)
	hole.Anchored = true; hole.CanCollide = false
	hole.Color = Color3.fromRGB(15,15,15)
	hole.Material = Enum.Material.SmoothPlastic
	hole.Parent = workspace
	makeBillboard(hole, "🕳️ HOLE! -30%", Color3.fromRGB(255,80,80))
end

-- 🏪 Shop
local shopPart = Instance.new("Part")
shopPart.Name = "ShopPart"
shopPart.Size = Vector3.new(10,5,10)
shopPart.Position = Vector3.new(0,2.5,-50)
shopPart.Anchored = true
shopPart.Color = Color3.fromRGB(0,162,255)
shopPart.Material = Enum.Material.Neon
shopPart.Parent = workspace
makeBillboard(shopPart, "🏪 SHOP\nWalk here!", Color3.new(1,1,1))
local sl = Instance.new("PointLight"); sl.Brightness=4; sl.Range=22; sl.Color=Color3.fromRGB(0,162,255); sl.Parent=shopPart
task.spawn(function()
	while true do
		TweenService:Create(sl, TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Brightness=6}):Play()
		task.wait(1)
		TweenService:Create(sl, TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Brightness=2}):Play()
		task.wait(1)
	end
end)

-- ⚔️ Battle Zone
local battleZone = Instance.new("Part")
battleZone.Name = "BattleZone"
battleZone.Size = Vector3.new(30, 0.5, 30)
battleZone.Position = Vector3.new(0, 0.3, 80)
battleZone.Anchored = true
battleZone.CanCollide = true
battleZone.Color = Color3.fromRGB(120, 0, 80)
battleZone.Material = Enum.Material.Neon
battleZone.Transparency = 0.15
battleZone.Parent = workspace
do
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0,220,0,70)
	bb.StudsOffset = Vector3.new(0,5,0)
	bb.AlwaysOnTop = true
	bb.Parent = battleZone
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundColor3 = Color3.fromRGB(80,0,40)
	lbl.BackgroundTransparency = 0.2
	lbl.Text = "⚔️ BATTLE ZONE\nSteal coins here!"
	lbl.TextColor3 = Color3.fromRGB(255,100,200)
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = bb
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,8)
	local pl = Instance.new("PointLight")
	pl.Brightness = 4; pl.Range = 20; pl.Color = Color3.fromRGB(180,0,100); pl.Parent = battleZone
end

-- 🎰 Gacha Machine
local gachaMachine = Instance.new("Part")
gachaMachine.Name = "GachaMachine"
gachaMachine.Shape = Enum.PartType.Ball
gachaMachine.Size = Vector3.new(5, 5, 5)
gachaMachine.Position = Vector3.new(-30, 2.5, -50)
gachaMachine.Anchored = true
gachaMachine.CanCollide = true
gachaMachine.Color = Color3.fromRGB(255, 100, 200)
gachaMachine.Material = Enum.Material.Neon
gachaMachine.Parent = workspace
do
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0,200,0,70)
	bb.StudsOffset = Vector3.new(0,5,0)
	bb.AlwaysOnTop = true
	bb.Parent = gachaMachine
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundColor3 = Color3.fromRGB(80,0,60)
	lbl.BackgroundTransparency = 0.2
	lbl.Text = "🎰 GACHA\n200 coins/spin"
	lbl.TextColor3 = Color3.fromRGB(255,200,100)
	lbl.TextStrokeTransparency = 0
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = bb
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,8)
	local pl = Instance.new("PointLight")
	pl.Brightness = 5; pl.Range = 18; pl.Color = Color3.fromRGB(255,100,200); pl.Parent = gachaMachine
	-- Rainbow pulse
	task.spawn(function()
		local colors = {
			Color3.fromRGB(255,80,80), Color3.fromRGB(255,160,0),
			Color3.fromRGB(100,255,80), Color3.fromRGB(80,160,255),
			Color3.fromRGB(200,80,255),
		}
		local i = 1
		while gachaMachine.Parent do
			TweenService:Create(gachaMachine, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Color=colors[i]}):Play()
			TweenService:Create(pl, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {Color=colors[i]}):Play()
			i = (i % #colors) + 1
			task.wait(0.8)
		end
	end)
end

-- Trees
math.randomseed(12345)
for i = 1, 40 do
	local angle = math.random()*math.pi*2
	local dist = math.random(30,220)
	local x = math.cos(angle)*dist
	local z = math.sin(angle)*dist
	if math.abs(z+50)>15 or math.abs(x)>15 then
		local trunk = Instance.new("Part")
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(8,1.5,1.5)
		trunk.CFrame = CFrame.new(x,4,z)*CFrame.Angles(0,0,math.pi/2)
		trunk.Anchored=true; trunk.Color=Color3.fromRGB(106,75,45); trunk.Material=Enum.Material.Wood; trunk.Parent=workspace
		local leaves = Instance.new("Part")
		leaves.Shape=Enum.PartType.Ball; leaves.Size=Vector3.new(6,6,6)
		leaves.Position=Vector3.new(x,9,z); leaves.Anchored=true
		leaves.Color=Color3.fromRGB(math.random(60,100),math.random(120,180),math.random(40,80))
		leaves.Material=Enum.Material.Grass; leaves.Parent=workspace
	end
end

local lighting = game:GetService("Lighting")
lighting.Brightness = 2; lighting.TimeOfDay = "14:00:00"
local atm = Instance.new("Atmosphere"); atm.Density=0.3; atm.Haze=0.5; atm.Parent=lighting

print("MapSetup loaded!")
