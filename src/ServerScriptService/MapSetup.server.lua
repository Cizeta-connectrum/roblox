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

-- ===== TERRAIN =====

-- Mountains
local function makeMountain(x, z, height, radius)
	local base = Instance.new("Part")
	base.Size = Vector3.new(radius*2, height, radius*2)
	base.Position = Vector3.new(x, height/2, z)
	base.Anchored = true; base.CanCollide = true
	base.Color = Color3.fromRGB(100, 90, 80)
	base.Material = Enum.Material.Rock
	base.Parent = workspace
	local snow = Instance.new("Part")
	snow.Size = Vector3.new(radius*0.6, height*0.25, radius*0.6)
	snow.Position = Vector3.new(x, height*0.9, z)
	snow.Anchored = true; snow.CanCollide = true
	snow.Color = Color3.fromRGB(240, 240, 255)
	snow.Material = Enum.Material.SmoothPlastic
	snow.Parent = workspace
end
makeMountain(120, 120, 80, 30)
makeMountain(-130, 90, 60, 22)
makeMountain(80, -140, 70, 25)
makeMountain(-100, -120, 90, 35)
makeMountain(170, -50, 50, 18)
makeMountain(-60, 170, 65, 28)

-- Cave entrance arch at (-130, 0, 90) area
local caveOuter = Instance.new("Part")
caveOuter.Size = Vector3.new(18, 20, 10)
caveOuter.Position = Vector3.new(-130, 10, 62)
caveOuter.Anchored = true; caveOuter.CanCollide = true
caveOuter.Color = Color3.fromRGB(80,70,60); caveOuter.Material = Enum.Material.Rock
caveOuter.Parent = workspace

local caveHole = Instance.new("Part")
caveHole.Size = Vector3.new(10, 14, 40)
caveHole.Position = Vector3.new(-130, 7, 55)
caveHole.Anchored = true; caveHole.CanCollide = false
caveHole.Color = Color3.fromRGB(10,5,5); caveHole.Material = Enum.Material.SmoothPlastic
caveHole.Transparency = 0.0; caveHole.CastShadow = false; caveHole.Parent = workspace
for _, cfg in ipairs({
	{Vector3.new(10,14,40), Vector3.new(-136,7,55)},
	{Vector3.new(10,14,40), Vector3.new(-124,7,55)},
	{Vector3.new(22,5,40),  Vector3.new(-130,16,55)},
	{Vector3.new(22,3,40),  Vector3.new(-130,0.5,55)},
}) do
	local p = Instance.new("Part"); p.Size=cfg[1]; p.Position=cfg[2]
	p.Anchored=true; p.CanCollide=true
	p.Color=Color3.fromRGB(60,55,50); p.Material=Enum.Material.Rock; p.Parent=workspace
end
local cl = Instance.new("PointLight"); cl.Brightness=1; cl.Range=30; cl.Color=Color3.fromRGB(150,100,50)
cl.Parent = caveHole

-- Valley
local valley = Instance.new("Part")
valley.Size = Vector3.new(60, 2, 80)
valley.Position = Vector3.new(40, -3, 30)
valley.Anchored = true; valley.CanCollide = true
valley.Color = Color3.fromRGB(40, 60, 30); valley.Material = Enum.Material.Grass
valley.Parent = workspace
local valleyFog = Instance.new("Part")
valleyFog.Size = Vector3.new(60, 8, 80)
valleyFog.Position = Vector3.new(40, 1, 30)
valleyFog.Anchored = true; valleyFog.CanCollide = false
valleyFog.Color = Color3.fromRGB(200,220,255); valleyFog.Material = Enum.Material.SmoothPlastic
valleyFog.Transparency = 0.92; valleyFog.CastShadow = false; valleyFog.Parent = workspace

-- Rock obstacles
math.randomseed(99991)
local rockPositions = {
	{20,50},{-50,20},{90,30},{-20,-80},{60,-60},{-90,60},{110,-100},
	{-150,40},{30,130},{-70,-150},{140,80},{-120,-70},{50,-120},{-40,100}
}
for _,rp in ipairs(rockPositions) do
	local r = Instance.new("Part")
	r.Size = Vector3.new(math.random(4,12), math.random(3,9), math.random(4,12))
	r.Position = Vector3.new(rp[1], r.Size.Y/2, rp[2])
	r.Anchored = true; r.CanCollide = true
	r.Color = Color3.fromRGB(math.random(80,120), math.random(75,110), math.random(70,100))
	r.Material = Enum.Material.Rock; r.Parent = workspace
end

-- ===== SKY CASTLE (LAPUTA) =====
local islandBase = Instance.new("Part")
islandBase.Name = "SkyIsland"
islandBase.Size = Vector3.new(120, 20, 120)
islandBase.Position = Vector3.new(0, 390, 0)
islandBase.Anchored = true; islandBase.CanCollide = true
islandBase.Color = Color3.fromRGB(90, 130, 60); islandBase.Material = Enum.Material.Grass
islandBase.Parent = workspace

local islandRock = Instance.new("Part")
islandRock.Size = Vector3.new(100, 30, 100)
islandRock.Position = Vector3.new(0, 370, 0)
islandRock.Anchored = true; islandRock.CanCollide = true
islandRock.Color = Color3.fromRGB(100, 85, 60); islandRock.Material = Enum.Material.Rock
islandRock.Parent = workspace

local tower = Instance.new("Part")
tower.Size = Vector3.new(20, 60, 20)
tower.Position = Vector3.new(0, 430, 0)
tower.Anchored = true; tower.CanCollide = true
tower.Color = Color3.fromRGB(200, 190, 160); tower.Material = Enum.Material.SmoothPlastic
tower.Parent = workspace

local roof = Instance.new("Part")
roof.Size = Vector3.new(24, 20, 24)
roof.Position = Vector3.new(0, 470, 0)
roof.Anchored = true; roof.CanCollide = true
roof.Color = Color3.fromRGB(50, 120, 80); roof.Material = Enum.Material.SmoothPlastic
roof.Parent = workspace

for _, cfg in ipairs({
	{Vector3.new(120,15,8), Vector3.new(0,408,56)},
	{Vector3.new(120,15,8), Vector3.new(0,408,-56)},
	{Vector3.new(8,15,120), Vector3.new(56,408,0)},
	{Vector3.new(8,15,120), Vector3.new(-56,408,0)},
}) do
	local wall = Instance.new("Part"); wall.Size=cfg[1]; wall.Position=cfg[2]
	wall.Anchored=true; wall.CanCollide=true
	wall.Color=Color3.fromRGB(180,170,140); wall.Material=Enum.Material.SmoothPlastic
	wall.Parent=workspace
end

for _, cpos in ipairs({
	Vector3.new(50,415,50), Vector3.new(-50,415,50),
	Vector3.new(50,415,-50), Vector3.new(-50,415,-50)
}) do
	local ct = Instance.new("Part"); ct.Size=Vector3.new(12,30,12)
	ct.Position=cpos; ct.Anchored=true; ct.CanCollide=true
	ct.Color=Color3.fromRGB(190,180,150); ct.Material=Enum.Material.SmoothPlastic; ct.Parent=workspace
end

local crystal = Instance.new("Part")
crystal.Name = "LapturaCrystal"
crystal.Size = Vector3.new(6,10,6)
crystal.Position = Vector3.new(0, 465, 0)
crystal.Anchored = true; crystal.CanCollide = false
crystal.Color = Color3.fromRGB(100,255,200); crystal.Material = Enum.Material.Neon
crystal.Transparency = 0.3; crystal.Parent = workspace
local cLight = Instance.new("PointLight"); cLight.Brightness=5; cLight.Range=40; cLight.Color=Color3.fromRGB(100,255,200); cLight.Parent=crystal

makeBillboard(tower, "LAPUTA Sky Castle", Color3.new(1,1,0))

-- Light beam warp point on the ground
local warpBeam = Instance.new("Part")
warpBeam.Name = "PendantWarp"
warpBeam.Size = Vector3.new(6, 400, 6)
warpBeam.Position = Vector3.new(0, 200, -20)
warpBeam.Anchored = true; warpBeam.CanCollide = false
warpBeam.Color = Color3.fromRGB(255,255,100); warpBeam.Material = Enum.Material.Neon
warpBeam.Transparency = 0.7; warpBeam.CastShadow = false; warpBeam.Parent = workspace
local warpLight = Instance.new("PointLight"); warpLight.Brightness=3; warpLight.Range=20; warpLight.Color=Color3.fromRGB(255,255,100); warpLight.Parent=warpBeam
makeBillboard(warpBeam, "LAPUTA WARP\n5000 coins needed", Color3.fromRGB(255,255,100))

task.spawn(function()
	while true do
		TweenService:Create(warpBeam, TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.5}):Play()
		task.wait(1.5)
		TweenService:Create(warpBeam, TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.85}):Play()
		task.wait(1.5)
	end
end)

print("MapSetup loaded!")
