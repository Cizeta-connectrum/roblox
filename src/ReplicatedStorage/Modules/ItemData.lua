-- ItemData.lua
-- Defines all item types in the game

local ItemData = {}

ItemData.Items = {
	-- Resources
	wood = {
		name = "wood",
		displayName = "Wood",
		icon = "rbxassetid://0",
		stackable = true,
		maxStack = 99,
		itemType = "resource",
	},
	stone = {
		name = "stone",
		displayName = "Stone",
		icon = "rbxassetid://0",
		stackable = true,
		maxStack = 99,
		itemType = "resource",
	},
	fiber = {
		name = "fiber",
		displayName = "Fiber",
		icon = "rbxassetid://0",
		stackable = true,
		maxStack = 99,
		itemType = "resource",
	},

	-- Tools
	axe = {
		name = "axe",
		displayName = "Axe",
		icon = "rbxassetid://0",
		stackable = false,
		maxStack = 1,
		itemType = "tool",
		craftRequires = { wood = 2, stone = 1 },
	},
	pickaxe = {
		name = "pickaxe",
		displayName = "Pickaxe",
		icon = "rbxassetid://0",
		stackable = false,
		maxStack = 1,
		itemType = "tool",
		craftRequires = { wood = 1, stone = 2 },
	},

	-- Buildings
	wall = {
		name = "wall",
		displayName = "Wall",
		icon = "rbxassetid://0",
		stackable = true,
		maxStack = 20,
		itemType = "building",
		craftRequires = { wood = 4 },
	},
	floor = {
		name = "floor",
		displayName = "Floor",
		icon = "rbxassetid://0",
		stackable = true,
		maxStack = 20,
		itemType = "building",
		craftRequires = { wood = 2 },
	},
	campfire = {
		name = "campfire",
		displayName = "Campfire",
		icon = "rbxassetid://0",
		stackable = true,
		maxStack = 5,
		itemType = "building",
		craftRequires = { wood = 3, stone = 1 },
	},
}

return ItemData
