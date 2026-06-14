-- MapSetup.server.lua
-- Creates the game map for CoinSimulator: baseplate, shop, decorations, lighting

local Lighting = game:GetService("Lighting")

-- ============================================================
-- Baseplate (500x500 green)
-- ============================================================
local baseplate = workspace:FindFirstChild("Baseplate")
if not baseplate then
	baseplate = Instance.new("Part")
	baseplate.Name = "Baseplate"
	baseplate.Parent = workspace
end
baseplate.Anchored = true
baseplate.Size = Vector3.new(500, 2, 500)
baseplate.CFrame = CFrame.new(0, -1, 0)
baseplate.Color = Color3.fromRGB(50, 160, 60)
baseplate.Material = Enum.Material.Grass
baseplate.CanCollide = true

-- ============================================================
-- Shop Part
-- ============================================================
local shopPart = Instance.new("Part")
shopPart.Name = "ShopPart"
shopPart.Anchored = true
shopPart.Size = Vector3.new(10, 5, 10)
shopPart.CFrame = CFrame.new(0, 2.5, -50)
shopPart.Color = Color3.fromRGB(0, 120, 255)
shopPart.Material = Enum.Material.SmoothPlastic
shopPart.CanCollide = true
shopPart.Parent = workspace

-- BillboardGui on the shop
local shopBB = Instance.new("BillboardGui")
shopBB.Size = UDim2.new(0, 200, 0, 60)
shopBB.StudsOffset = Vector3.new(0, 4, 0)
shopBB.AlwaysOnTop = false
shopBB.Parent = shopPart

local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.fromScale(1, 1)
shopLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shopLabel.BackgroundTransparency = 0.3
shopLabel.Text = "🛒 SHOP\nPress E"
shopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
shopLabel.TextScaled = true
shopLabel.Font = Enum.Font.GothamBold
shopLabel.Parent = shopBB

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.1, 0)
corner.Parent = shopLabel

-- Shop PointLight
local shopLight = Instance.new("PointLight")
shopLight.Color = Color3.fromRGB(0, 160, 255)
shopLight.Brightness = 3
shopLight.Range = 20
shopLight.Parent = shopPart

-- ============================================================
-- Decorative trees
-- ============================================================
local function createTree(x, z)
	local treeFolder = Instance.new("Model")
	treeFolder.Name = "Tree"
	treeFolder.Parent = workspace

	-- Trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(8, 1.5, 1.5)
	trunk.CFrame = CFrame.new(x, 4, z) * CFrame.Angles(0, 0, math.pi / 2)
	trunk.Color = Color3.fromRGB(100, 65, 35)
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.Parent = treeFolder

	-- Leaves
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(8, 8, 8)
	leaves.CFrame = CFrame.new(x, 10, z)
	leaves.Color = Color3.fromRGB(40, 140, 40)
	leaves.Material = Enum.Material.Grass
	leaves.Anchored = true
	leaves.CanCollide = false
	leaves.Parent = treeFolder
end

math.randomseed(12345)
local treePositions = {}
for i = 1, 30 do
	local x, z
	local attempts = 0
	repeat
		x = math.random(-220, 220)
		z = math.random(-220, 220)
		attempts = attempts + 1
		-- Keep away from shop area and spawn
	until (math.abs(x) > 20 or math.abs(z + 50) > 20) and (math.abs(x) > 15 or math.abs(z) > 15) or attempts > 20
	createTree(x, z)
end

-- ============================================================
-- Lighting
-- ============================================================
Lighting.Ambient = Color3.fromRGB(80, 80, 100)
Lighting.Brightness = 2
Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 200)
Lighting.OutdoorAmbient = Color3.fromRGB(120, 140, 160)
Lighting.ShadowSoftness = 0.5
Lighting.ClockTime = 14  -- afternoon
Lighting.FogEnd = 800
Lighting.FogColor = Color3.fromRGB(200, 220, 255)

-- Atmosphere effect
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
if not atmosphere then
	atmosphere = Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
end
atmosphere.Density = 0.3
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(180, 200, 240)
atmosphere.Decay = Color3.fromRGB(100, 120, 160)
atmosphere.Glare = 0.5
atmosphere.Haze = 1

print("[MapSetup] Map created!")
