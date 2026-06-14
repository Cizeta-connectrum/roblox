-- MapSetup.server.lua
-- Sets up the game map with baseplate, shop, decorations, and atmosphere

local TweenService = game:GetService("TweenService")

-- Remove default baseplate if it exists
local existingBaseplate = workspace:FindFirstChild("Baseplate")
if existingBaseplate then
	existingBaseplate:Destroy()
end

-- Create large baseplate
local baseplate = Instance.new("Part")
baseplate.Name = "Baseplate"
baseplate.Size = Vector3.new(500, 1, 500)
baseplate.Position = Vector3.new(0, -0.5, 0)
baseplate.Anchored = true
baseplate.Locked = true
baseplate.Color = Color3.fromRGB(106, 127, 63)  -- Grass green
baseplate.Material = Enum.Material.Grass
baseplate.Parent = workspace

-- Create shop part
local shopPart = Instance.new("Part")
shopPart.Name = "ShopPart"
shopPart.Size = Vector3.new(10, 5, 10)
shopPart.Position = Vector3.new(0, 2.5, -50)
shopPart.Anchored = true
shopPart.Color = Color3.fromRGB(0, 162, 255)  -- Bright blue
shopPart.Material = Enum.Material.Neon
shopPart.Parent = workspace

-- Shop billboard
local shopBillboard = Instance.new("BillboardGui")
shopBillboard.Size = UDim2.new(0, 200, 0, 80)
shopBillboard.StudsOffset = Vector3.new(0, 4, 0)
shopBillboard.AlwaysOnTop = true
shopBillboard.Parent = shopPart

local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(1, 0, 1, 0)
shopLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shopLabel.BackgroundTransparency = 0.3
shopLabel.Text = "🏪 SHOP\nPress E to Open"
shopLabel.Font = Enum.Font.GothamBold
shopLabel.TextScaled = true
shopLabel.TextColor3 = Color3.new(1, 1, 1)
shopLabel.TextStrokeTransparency = 0
shopLabel.Parent = shopBillboard

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.1, 0)
corner.Parent = shopLabel

-- Shop glow animation
local shopLight = Instance.new("PointLight")
shopLight.Brightness = 3
shopLight.Range = 20
shopLight.Color = Color3.fromRGB(0, 162, 255)
shopLight.Parent = shopPart

-- Animate shop light
task.spawn(function()
	while true do
		TweenService:Create(shopLight, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 5}):Play()
		task.wait(1)
		TweenService:Create(shopLight, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Brightness = 2}):Play()
		task.wait(1)
	end
end)

-- Spawn sign above shop
local signPart = Instance.new("Part")
signPart.Name = "ShopSign"
signPart.Size = Vector3.new(12, 3, 0.5)
signPart.Position = Vector3.new(0, 7, -50)
signPart.Anchored = true
signPart.Color = Color3.fromRGB(255, 200, 0)
signPart.Material = Enum.Material.Neon
signPart.Parent = workspace

local signGui = Instance.new("SurfaceGui")
signGui.Face = Enum.NormalId.Front
signGui.Parent = signPart

local signLabel = Instance.new("TextLabel")
signLabel.Size = UDim2.new(1, 0, 1, 0)
signLabel.BackgroundTransparency = 1
signLabel.Text = "🪙 COIN SHOP 🪙"
signLabel.Font = Enum.Font.GothamBold
signLabel.TextScaled = true
signLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
signLabel.Parent = signGui

-- Create decorative trees
local function createTree(x, z)
	local treeFolder = Instance.new("Folder")
	treeFolder.Name = "Tree"
	treeFolder.Parent = workspace

	-- Trunk
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(8, 1.5, 1.5)
	trunk.CFrame = CFrame.new(x, 4, z) * CFrame.Angles(0, 0, math.pi / 2)
	trunk.Anchored = true
	trunk.Color = Color3.fromRGB(106, 75, 45)
	trunk.Material = Enum.Material.Wood
	trunk.Parent = treeFolder

	-- Leaves
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(6, 6, 6)
	leaves.Position = Vector3.new(x, 9, z)
	leaves.Anchored = true
	leaves.Color = Color3.fromRGB(
		math.random(60, 100),
		math.random(120, 180),
		math.random(40, 80)
	)
	leaves.Material = Enum.Material.Grass
	leaves.Parent = treeFolder
end

-- Place trees randomly around the map (avoiding center/shop area)
math.randomseed(12345)
for i = 1, 40 do
	local angle = math.random() * math.pi * 2
	local dist = math.random(30, 220)
	local x = math.cos(angle) * dist
	local z = math.sin(angle) * dist

	-- Skip area near shop
	if math.abs(z + 50) > 15 or math.abs(x) > 15 then
		createTree(x, z)
	end
end

-- Spawn point marker
local spawnCircle = Instance.new("Part")
spawnCircle.Name = "SpawnPoint"
spawnCircle.Shape = Enum.PartType.Cylinder
spawnCircle.Size = Vector3.new(0.2, 8, 8)
spawnCircle.CFrame = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.pi/2)
spawnCircle.Anchored = true
spawnCircle.Color = Color3.fromRGB(0, 255, 100)
spawnCircle.Material = Enum.Material.Neon
spawnCircle.CanCollide = false
spawnCircle.Parent = workspace

-- Set ambient lighting
local lighting = game:GetService("Lighting")
lighting.Ambient = Color3.fromRGB(80, 80, 80)
lighting.Brightness = 2
lighting.ColorShift_Bottom = Color3.fromRGB(0, 20, 40)
lighting.ColorShift_Top = Color3.fromRGB(20, 40, 80)
lighting.TimeOfDay = "14:00:00"

-- Add atmosphere
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Offset = 0.25
atmosphere.Color = Color3.fromRGB(199, 210, 255)
atmosphere.Decay = Color3.fromRGB(106, 112, 125)
atmosphere.Glare = 0.2
atmosphere.Haze = 0.5
atmosphere.Parent = lighting

-- Add sky
local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
sky.Parent = lighting

print("MapSetup loaded!")
