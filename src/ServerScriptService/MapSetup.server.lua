-- MapSetup.server.lua
-- Creates the game world

local workspace = game:GetService("Workspace")

-- Large baseplate
local baseplate = Instance.new("Part")
baseplate.Name = "Baseplate"
baseplate.Size = Vector3.new(600, 1, 600)
baseplate.Position = Vector3.new(0, -0.5, 0)
baseplate.Anchored = true
baseplate.BrickColor = BrickColor.new("Bright green")
baseplate.Material = Enum.Material.Grass
baseplate.Parent = workspace

-- Atmosphere
local lighting = game:GetService("Lighting")
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Color = Color3.fromRGB(199, 220, 255)
atmosphere.Decay = Color3.fromRGB(106, 127, 189)
atmosphere.Glare = 0
atmosphere.Haze = 0
atmosphere.Parent = lighting

lighting.Sky = Instance.new("Sky")
lighting.Sky.Parent = lighting

-- Helper: BillboardGui
local function makeBillboard(parent, text, textColor)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 5, 0)
    bb.AlwaysOnTop = false
    bb.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = bb
end

-- Boost pads (5)
local boostPositions = {
    Vector3.new(80, 0.5, 60),
    Vector3.new(-120, 0.5, 100),
    Vector3.new(150, 0.5, -80),
    Vector3.new(-60, 0.5, -150),
    Vector3.new(30, 0.5, 170),
}
for _, pos in ipairs(boostPositions) do
    local pad = Instance.new("Part")
    pad.Name = "BoostPad"
    pad.Size = Vector3.new(8, 1, 8)
    pad.Position = pos
    pad.Anchored = true
    pad.BrickColor = BrickColor.new("Bright yellow")
    pad.Material = Enum.Material.Neon
    pad.Parent = workspace
    makeBillboard(pad, "⚡ SPEED BOOST!", Color3.fromRGB(255, 255, 0))
end

-- Slow zones (4)
local slowPositions = {
    Vector3.new(-100, 0.25, -100),
    Vector3.new(130, 0.25, 130),
    Vector3.new(-170, 0.25, 50),
    Vector3.new(60, 0.25, -170),
}
for _, pos in ipairs(slowPositions) do
    local zone = Instance.new("Part")
    zone.Name = "SlowZone"
    zone.Size = Vector3.new(12, 0.5, 12)
    zone.Position = pos
    zone.Anchored = true
    zone.BrickColor = BrickColor.new("Dark indigo")
    zone.Material = Enum.Material.Neon
    zone.Transparency = 0.4
    zone.Parent = workspace
    makeBillboard(zone, "🐌 SLOW ZONE", Color3.fromRGB(180, 100, 255))
end

-- Shop building
local shopPart = Instance.new("Part")
shopPart.Name = "ShopPart"
shopPart.Size = Vector3.new(12, 8, 12)
shopPart.Position = Vector3.new(0, 4, -80)
shopPart.Anchored = true
shopPart.BrickColor = BrickColor.new("Bright blue")
shopPart.Material = Enum.Material.SmoothPlastic
shopPart.Parent = workspace

local shopBb = Instance.new("BillboardGui")
shopBb.Size = UDim2.new(0, 300, 0, 70)
shopBb.StudsOffset = Vector3.new(0, 8, 0)
shopBb.AlwaysOnTop = true
shopBb.Parent = shopPart

local shopLabel = Instance.new("TextLabel")
shopLabel.Size = UDim2.new(1, 0, 1, 0)
shopLabel.BackgroundTransparency = 1
shopLabel.Text = "🏪 SHOP (walk in!)"
shopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
shopLabel.TextScaled = true
shopLabel.Font = Enum.Font.GothamBold
shopLabel.Parent = shopBb

-- 40 decorative trees
math.randomseed(42)
local treePositions = {}
local function isTooClose(pos)
    for _, p in ipairs(treePositions) do
        if (p - pos).Magnitude < 12 then return true end
    end
    -- avoid center and shop
    if pos.Magnitude < 30 then return true end
    if (pos - Vector3.new(0, 0, -80)).Magnitude < 20 then return true end
    return false
end

local treesPlaced = 0
local attempts = 0
while treesPlaced < 40 and attempts < 500 do
    attempts = attempts + 1
    local x = math.random(-200, 200)
    local z = math.random(-200, 200)
    local pos2d = Vector3.new(x, 0, z)
    if not isTooClose(pos2d) then
        table.insert(treePositions, pos2d)
        treesPlaced = treesPlaced + 1

        -- Trunk
        local trunk = Instance.new("Part")
        trunk.Shape = Enum.PartType.Cylinder
        trunk.Size = Vector3.new(5, 1.5, 1.5)
        trunk.Position = Vector3.new(x, 2.5, z)
        trunk.Anchored = true
        trunk.BrickColor = BrickColor.new("Reddish brown")
        trunk.Material = Enum.Material.Wood
        trunk.Parent = workspace

        -- Top
        local top = Instance.new("Part")
        top.Shape = Enum.PartType.Ball
        top.Size = Vector3.new(5, 5, 5)
        top.Position = Vector3.new(x, 7, z)
        top.Anchored = true
        top.BrickColor = BrickColor.new("Bright green")
        top.Material = Enum.Material.Grass
        top.Parent = workspace
    end
end
