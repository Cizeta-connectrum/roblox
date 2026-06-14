-- InventoryController.client.lua
-- Toggle inventory UI with Tab, display item grid, show crafting panel

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local RemoteEvents = require(Modules:WaitForChild("RemoteEvents"))
local ItemData = require(Modules:WaitForChild("ItemData"))
local RecipeData = require(Modules:WaitForChild("RecipeData"))

-- Wait for ClientMain to set up shared state
local LocalInventory = _G.LocalInventory or {}

-- Build the inventory ScreenGui
local invGui = Instance.new("ScreenGui")
invGui.Name = "InventoryUI"
invGui.ResetOnSpawn = false
invGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
invGui.Enabled = false
invGui.Parent = PlayerGui

-- Main panel
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 700, 0, 450)
mainPanel.Position = UDim2.new(0.5, -350, 0.5, -225)
mainPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainPanel.BackgroundTransparency = 0.1
mainPanel.BorderSizePixel = 0
mainPanel.Parent = invGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainPanel

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Inventory & Crafting  [Tab to close]"
titleLabel.Parent = mainPanel

-- Left: inventory grid
local invSection = Instance.new("Frame")
invSection.Name = "InventorySection"
invSection.Size = UDim2.new(0.5, -10, 1, -50)
invSection.Position = UDim2.new(0, 10, 0, 45)
invSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
invSection.BorderSizePixel = 0
invSection.Parent = mainPanel

local invTitle = Instance.new("TextLabel")
invTitle.Size = UDim2.new(1, 0, 0, 30)
invTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
invTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
invTitle.TextScaled = true
invTitle.Font = Enum.Font.Gotham
invTitle.Text = "Items"
invTitle.Parent = invSection

local invGrid = Instance.new("ScrollingFrame")
invGrid.Name = "Grid"
invGrid.Size = UDim2.new(1, -10, 1, -35)
invGrid.Position = UDim2.new(0, 5, 0, 33)
invGrid.BackgroundTransparency = 1
invGrid.ScrollBarThickness = 6
invGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
invGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
invGrid.Parent = invSection

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 80, 0, 80)
gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
gridLayout.SortOrder = Enum.SortOrder.Name
gridLayout.Parent = invGrid

-- Right: crafting panel
local craftSection = Instance.new("Frame")
craftSection.Name = "CraftingSection"
craftSection.Size = UDim2.new(0.5, -10, 1, -50)
craftSection.Position = UDim2.new(0.5, 5, 0, 45)
craftSection.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
craftSection.BorderSizePixel = 0
craftSection.Parent = mainPanel

local craftTitle = Instance.new("TextLabel")
craftTitle.Size = UDim2.new(1, 0, 0, 30)
craftTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
craftTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
craftTitle.TextScaled = true
craftTitle.Font = Enum.Font.Gotham
craftTitle.Text = "Crafting"
craftTitle.Parent = craftSection

local craftList = Instance.new("ScrollingFrame")
craftList.Name = "List"
craftList.Size = UDim2.new(1, -10, 1, -35)
craftList.Position = UDim2.new(0, 5, 0, 33)
craftList.BackgroundTransparency = 1
craftList.ScrollBarThickness = 6
craftList.CanvasSize = UDim2.new(0, 0, 0, 0)
craftList.AutomaticCanvasSize = Enum.AutomaticSize.Y
craftList.Parent = craftSection

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = craftList

-- Helper: create inventory slot
local function createSlot(itemId, count)
	local slot = Instance.new("Frame")
	slot.Name = itemId
	slot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	slot.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = slot

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Gotham
	local def = ItemData.Items[itemId]
	nameLabel.Text = def and def.displayName or itemId
	nameLabel.Parent = slot

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, 0, 0.4, 0)
	countLabel.Position = UDim2.new(0, 0, 0.6, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
	countLabel.TextScaled = true
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Text = "x" .. tostring(count)
	countLabel.Parent = slot

	return slot
end

-- Refresh inventory grid
local function refreshInventory()
	-- Clear existing slots
	for _, child in ipairs(invGrid:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local inv = _G.LocalInventory or LocalInventory
	local hasItems = false
	for itemId, count in pairs(inv) do
		if count > 0 then
			hasItems = true
			local slot = createSlot(itemId, count)
			slot.Parent = invGrid
		end
	end

	if not hasItems then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyLabel"
		emptyLabel.Size = UDim2.new(1, 0, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.TextScaled = true
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Text = "No items"
		emptyLabel.Parent = invGrid
	end
end

-- Helper: check if player can craft a recipe
local function canCraft(recipe)
	local inv = _G.LocalInventory or LocalInventory
	for itemId, count in pairs(recipe.ingredients) do
		if (inv[itemId] or 0) < count then
			return false
		end
	end
	return true
end

-- Status label for crafting feedback
local craftStatus = Instance.new("TextLabel")
craftStatus.Name = "CraftStatus"
craftStatus.Size = UDim2.new(1, -10, 0, 30)
craftStatus.Position = UDim2.new(0, 5, 1, -35)
craftStatus.BackgroundTransparency = 1
craftStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
craftStatus.TextScaled = true
craftStatus.Font = Enum.Font.Gotham
craftStatus.Text = ""
craftStatus.Parent = craftSection

-- Refresh crafting list
local function refreshCrafting()
	for _, child in ipairs(craftList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for i, recipe in ipairs(RecipeData.Recipes) do
		local recipeFrame = Instance.new("Frame")
		recipeFrame.Name = "Recipe_" .. recipe.result
		recipeFrame.Size = UDim2.new(1, -5, 0, 70)
		recipeFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		recipeFrame.BorderSizePixel = 0
		recipeFrame.LayoutOrder = i
		recipeFrame.Parent = craftList

		local recipeCorner = Instance.new("UICorner")
		recipeCorner.CornerRadius = UDim.new(0, 6)
		recipeCorner.Parent = recipeFrame

		-- Recipe name
		local def = ItemData.Items[recipe.result]
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.65, 0, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 8, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = def and def.displayName or recipe.result
		nameLabel.Parent = recipeFrame

		-- Ingredients text
		local ingParts = {}
		for itemId, count in pairs(recipe.ingredients) do
			local iDef = ItemData.Items[itemId]
			table.insert(ingParts, (iDef and iDef.displayName or itemId) .. " x" .. count)
		end
		local ingLabel = Instance.new("TextLabel")
		ingLabel.Size = UDim2.new(0.65, 0, 0.45, 0)
		ingLabel.Position = UDim2.new(0, 8, 0.5, 0)
		ingLabel.BackgroundTransparency = 1
		ingLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		ingLabel.TextXAlignment = Enum.TextXAlignment.Left
		ingLabel.TextScaled = true
		ingLabel.Font = Enum.Font.Gotham
		ingLabel.Text = table.concat(ingParts, ", ")
		ingLabel.Parent = recipeFrame

		-- Craft button
		local craftBtn = Instance.new("TextButton")
		craftBtn.Name = "CraftBtn"
		craftBtn.Size = UDim2.new(0.3, -10, 0.7, 0)
		craftBtn.Position = UDim2.new(0.68, 0, 0.15, 0)
		craftBtn.BackgroundColor3 = canCraft(recipe) and Color3.fromRGB(60, 140, 60) or Color3.fromRGB(80, 80, 80)
		craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		craftBtn.TextScaled = true
		craftBtn.Font = Enum.Font.GothamBold
		craftBtn.Text = canCraft(recipe) and "Craft" or "Need more"
		craftBtn.BorderSizePixel = 0

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = craftBtn

		craftBtn.MouseButton1Click:Connect(function()
			if not canCraft(recipe) then
				craftStatus.Text = "Not enough materials!"
				craftStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
				task.delay(2, function() craftStatus.Text = "" end)
				return
			end

			local success, msg = RemoteEvents.CraftItem:InvokeServer(i)
			if success then
				craftStatus.Text = "Crafted " .. (def and def.displayName or recipe.result) .. "!"
				craftStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
			else
				craftStatus.Text = msg or "Craft failed"
				craftStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
			end
			task.delay(2, function() craftStatus.Text = "" end)
			refreshInventory()
			refreshCrafting()
		end)

		craftBtn.Parent = recipeFrame
	end
end

-- Callback for inventory updates
_G.OnInventoryUpdated = function(inv)
	if invGui.Enabled then
		refreshInventory()
		refreshCrafting()
	end
end

-- Toggle with Tab
local isOpen = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		isOpen = not isOpen
		invGui.Enabled = isOpen

		if isOpen then
			refreshInventory()
			refreshCrafting()
		end
	end
end)

print("[InventoryController] Inventory Controller initialized.")
