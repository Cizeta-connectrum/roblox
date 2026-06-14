-- BuildController.client.lua
-- Cycle buildable items with B, show ghost preview, place with click

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))
local ItemData = require(Modules:WaitForChild("ItemData"))

-- Buildable items and their ghost sizes
local BUILDABLES = {
	{ id = "wall",     size = Vector3.new(8, 6, 0.5),  color = Color3.fromRGB(210, 180, 140) },
	{ id = "floor",    size = Vector3.new(8, 0.5, 8),  color = Color3.fromRGB(210, 180, 140) },
	{ id = "campfire", size = Vector3.new(2, 1, 2),    color = Color3.fromRGB(255, 100, 0) },
}

local currentIndex = 0  -- 0 = build mode off
local ghostPart = nil
local buildModeLabel = nil

-- Create HUD label for build mode
local buildGui = Instance.new("ScreenGui")
buildGui.Name = "BuildUI"
buildGui.ResetOnSpawn = false
buildGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
buildGui.Parent = PlayerGui

buildModeLabel = Instance.new("TextLabel")
buildModeLabel.Name = "BuildModeLabel"
buildModeLabel.Size = UDim2.new(0, 300, 0, 40)
buildModeLabel.Position = UDim2.new(0.5, -150, 0, 60)
buildModeLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
buildModeLabel.BackgroundTransparency = 0.4
buildModeLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
buildModeLabel.TextScaled = true
buildModeLabel.Font = Enum.Font.GothamBold
buildModeLabel.Text = ""
buildModeLabel.Visible = false
buildModeLabel.Parent = buildGui

local function updateBuildLabel()
	if currentIndex == 0 then
		buildModeLabel.Visible = false
	else
		local item = BUILDABLES[currentIndex]
		local def = ItemData.Items[item.id]
		local inv = _G.LocalInventory or {}
		local count = inv[item.id] or 0
		buildModeLabel.Text = string.format("[B] %s  (x%d)  [Click to place]", def and def.displayName or item.id, count)
		buildModeLabel.Visible = true
	end
end

-- Create ghost part
local function createGhost(item)
	if ghostPart then
		ghostPart:Destroy()
		ghostPart = nil
	end

	if not item then return end

	local part = Instance.new("Part")
	part.Name = "GhostPreview"
	part.Size = item.size
	part.Color = item.color
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0.6
	part.CanCollide = false
	part.Anchored = true
	part.CastShadow = false
	part.Parent = workspace

	ghostPart = part
end

-- Destroy ghost part
local function destroyGhost()
	if ghostPart then
		ghostPart:Destroy()
		ghostPart = nil
	end
end

-- Cycle build item on B press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.B then
		currentIndex = currentIndex + 1
		if currentIndex > #BUILDABLES then
			currentIndex = 0
		end

		if currentIndex == 0 then
			destroyGhost()
		else
			createGhost(BUILDABLES[currentIndex])
		end
		updateBuildLabel()
	end
end)

-- Raycast params
local function getRaycastParams()
	local char = LocalPlayer.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if char then
		params.FilterDescendantsInstances = { char, ghostPart }
	end
	return params
end

-- Mouse move: update ghost position
RunService.RenderStepped:Connect(function()
	if currentIndex == 0 or not ghostPart then return end

	local params = getRaycastParams()
	local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 100, params)

	if result then
		local item = BUILDABLES[currentIndex]
		-- Snap to grid of 4 studs
		local pos = result.Position
		local snappedX = math.round(pos.X / 4) * 4
		local snappedZ = math.round(pos.Z / 4) * 4
		local snappedY = pos.Y + item.size.Y / 2

		ghostPart.CFrame = CFrame.new(snappedX, snappedY, snappedZ)

		-- Color ghost red if no inventory, green if can place
		local inv = _G.LocalInventory or {}
		local item2 = BUILDABLES[currentIndex]
		local count = inv[item2.id] or 0
		if count > 0 then
			ghostPart.Color = Color3.fromRGB(100, 220, 100)
		else
			ghostPart.Color = Color3.fromRGB(220, 80, 80)
		end
	end
end)

-- Mouse click: place building
Mouse.Button1Down:Connect(function()
	if currentIndex == 0 or not ghostPart then return end

	local item = BUILDABLES[currentIndex]
	local inv = _G.LocalInventory or {}
	if (inv[item.id] or 0) < 1 then
		print("[BuildController] No", item.id, "in inventory")
		return
	end

	local placeCFrame = ghostPart.CFrame
	RemoteEvents.PlaceBuilding:FireServer(item.id, placeCFrame)
	print("[BuildController] Placed", item.id, "at", placeCFrame.Position)

	-- Update local inventory optimistically
	if inv[item.id] then
		inv[item.id] = inv[item.id] - 1
		if inv[item.id] <= 0 then
			inv[item.id] = nil
		end
	end

	updateBuildLabel()

	-- Exit build mode if out of the item
	if (inv[item.id] or 0) < 1 then
		currentIndex = 0
		destroyGhost()
		updateBuildLabel()
	end
end)

print("[BuildController] Build Controller initialized.")
