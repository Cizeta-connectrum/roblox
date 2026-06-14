-- CoinController.client.lua
-- Handles coin collection effects on the client side

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))

-- Listen for UpdateCoins (handled primarily by HudController, but we relay)
-- This script focuses on the collect effect trigger

RemoteEvents.ShowCollectEffect.OnClientEvent:Connect(function(position, amount)
	-- Create a floating "+X" effect in the world using a BillboardGui on an invisible part
	local effectPart = Instance.new("Part")
	effectPart.Size = Vector3.new(0.1, 0.1, 0.1)
	effectPart.Anchored = true
	effectPart.CanCollide = false
	effectPart.Transparency = 1
	effectPart.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	effectPart.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 80, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = effectPart

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. tostring(amount)
	label.TextColor3 = Color3.fromRGB(255, 220, 0)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	-- Tween: float up and fade out over 1.2 seconds
	local startCFrame = effectPart.CFrame
	local endCFrame = startCFrame + Vector3.new(0, 4, 0)

	local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(effectPart, tweenInfo, { CFrame = endCFrame })
	local fadeTween = TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Linear), { TextTransparency = 1, TextStrokeTransparency = 1 })

	tween:Play()
	fadeTween:Play()

	tween.Completed:Connect(function()
		effectPart:Destroy()
	end)
end)
