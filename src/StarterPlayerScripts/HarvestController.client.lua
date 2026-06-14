-- HarvestController.client.lua
-- Handles raycasting toward resource nodes and harvesting on E press

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))

local HARVEST_RANGE = 20 -- max distance to harvest a node

-- Prompt UI
local promptGui = Instance.new("ScreenGui")
promptGui.Name = "HarvestPrompt"
promptGui.ResetOnSpawn = false
promptGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
promptGui.Parent = PlayerGui

local promptFrame = Instance.new("Frame")
promptFrame.Name = "PromptFrame"
promptFrame.Size = UDim2.new(0, 220, 0, 50)
promptFrame.Position = UDim2.new(0.5, -110, 0.7, 0)
promptFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
promptFrame.BackgroundTransparency = 0.3
promptFrame.BorderSizePixel = 0
promptFrame.Visible = false
promptFrame.Parent = promptGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = promptFrame

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, 0, 1, 0)
promptLabel.BackgroundTransparency = 1
promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
promptLabel.TextScaled = true
promptLabel.Font = Enum.Font.Gotham
promptLabel.Text = "[E] Harvest"
promptLabel.Parent = promptFrame

-- Current targeted node
local currentNode = nil

-- Check if a model is a resource node
local function isResourceNode(model)
	if not model then return false end
	return model:FindFirstChild("NodeType") ~= nil
		and model:FindFirstChild("Harvested") ~= nil
end

-- Get the model from a part
local function getNodeModel(part)
	if not part then return nil end
	local model = part:FindFirstAncestorWhichIsA("Model")
	if isResourceNode(model) then
		return model
	end
	return nil
end

-- Update loop: raycast from screen center toward mouse
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then
		currentNode = nil
		promptFrame.Visible = false
		return
	end

	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		currentNode = nil
		promptFrame.Visible = false
		return
	end

	-- Build raycast params to ignore character
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { char }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Ray from camera through mouse position
	local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * HARVEST_RANGE, rayParams)

	if result then
		local node = getNodeModel(result.Instance)
		local dist = (rootPart.Position - result.Position).Magnitude

		if node and dist <= HARVEST_RANGE then
			local harvested = node:FindFirstChild("Harvested")
			if harvested and not harvested.Value then
				currentNode = node
				promptFrame.Visible = true
				local nodeType = node:FindFirstChild("NodeType")
				local typeName = nodeType and nodeType.Value or "Resource"
				promptLabel.Text = "[E] Harvest " .. typeName:sub(1,1):upper() .. typeName:sub(2)
				return
			end
		end
	end

	currentNode = nil
	promptFrame.Visible = false
end)

-- E key press: harvest current node
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		if currentNode then
			RemoteEvents.HarvestResource:FireServer(currentNode)
			print("[HarvestController] Sent harvest request for", currentNode.Name)
		end
	end
end)

print("[HarvestController] Harvest Controller initialized.")
