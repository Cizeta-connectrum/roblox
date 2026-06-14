-- CoinController.client.lua
-- Handles collect effects on the client

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEventsModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents")
local RemoteEvents = require(RemoteEventsModule)

local ShowCollectEffect = RemoteEvents.ShowCollectEffect

-- Coin type colors for effects
local TYPE_COLORS = {
	Common = Color3.fromRGB(255, 215, 0),
	Rare = Color3.fromRGB(0, 120, 255),
	Epic = Color3.fromRGB(160, 0, 255),
	Legendary = Color3.fromRGB(255, 165, 0),
}

local camera = workspace.CurrentCamera

local function showCollectEffect(position, value, coinTypeName)
	-- Create a BillboardGui in workspace attached to a part
	local effectPart = Instance.new("Part")
	effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
	effectPart.Position = position + Vector3.new(0, 1, 0)
	effectPart.Anchored = true
	effectPart.CanCollide = false
	effectPart.Transparency = 1
	effectPart.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 80, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = effectPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. tostring(value)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = TYPE_COLORS[coinTypeName] or Color3.new(1, 1, 0)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard

	-- Animate: float up and fade out
	local startPos = effectPart.Position
	local endPos = startPos + Vector3.new(math.random(-2, 2), 4, math.random(-2, 2))

	local moveTween = TweenService:Create(
		effectPart,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = endPos }
	)

	local fadeTween = TweenService:Create(
		label,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }
	)

	moveTween:Play()
	fadeTween:Play()

	-- For legendary coins, make it bigger and more dramatic
	if coinTypeName == "Legendary" then
		label.Text = "⭐ +" .. tostring(value) .. " ⭐"
		billboard.Size = UDim2.new(0, 140, 0, 60)

		-- Extra sparkle effect
		local sparkPart = Instance.new("Part")
		sparkPart.Size = Vector3.new(1, 1, 1)
		sparkPart.Position = position
		sparkPart.Anchored = true
		sparkPart.CanCollide = false
		sparkPart.Transparency = 1
		sparkPart.Parent = workspace

		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(255, 165, 0)
		sparkles.Parent = sparkPart

		task.delay(0.5, function()
			sparkPart:Destroy()
		end)
	end

	task.delay(1.3, function()
		effectPart:Destroy()
	end)
end

ShowCollectEffect.OnClientEvent:Connect(showCollectEffect)

print("CoinController loaded!")
