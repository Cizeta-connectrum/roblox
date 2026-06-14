-- CraftingService.server.lua
-- Handles crafting requests from clients

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RemoteEvents"))
local RecipeData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("RecipeData"))
local ItemData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemData"))

-- Helper: check and consume ingredients from inventory
local function hasIngredients(inventory, ingredients)
	for itemId, count in pairs(ingredients) do
		if (inventory[itemId] or 0) < count then
			return false, "Not enough " .. itemId
		end
	end
	return true, "OK"
end

local function consumeIngredients(inventory, ingredients)
	for itemId, count in pairs(ingredients) do
		inventory[itemId] = (inventory[itemId] or 0) - count
		if inventory[itemId] <= 0 then
			inventory[itemId] = nil
		end
	end
end

local function addToInventory(inventory, itemId, amount)
	inventory[itemId] = (inventory[itemId] or 0) + amount
end

-- Handle CraftItem RemoteFunction
RemoteEvents.CraftItem.OnServerInvoke = function(player, recipeIndex)
	local PlayerData = _G.PlayerData
	if not PlayerData then
		return false, "Server not ready"
	end

	local data = PlayerData[player.UserId]
	if not data then
		return false, "Player data not found"
	end

	-- Validate recipe index
	if type(recipeIndex) ~= "number" or recipeIndex < 1 or recipeIndex > #RecipeData.Recipes then
		return false, "Invalid recipe"
	end

	local recipe = RecipeData.Recipes[recipeIndex]
	local inventory = data.inventory

	-- Check ingredients
	local canCraft, reason = hasIngredients(inventory, recipe.ingredients)
	if not canCraft then
		return false, reason
	end

	-- Check item data exists
	local itemDef = ItemData.Items[recipe.result]
	if not itemDef then
		return false, "Unknown item: " .. tostring(recipe.result)
	end

	-- Check stack limit
	local currentCount = inventory[recipe.result] or 0
	if not itemDef.stackable and currentCount >= 1 then
		return false, "Cannot stack this item"
	end
	if itemDef.stackable and currentCount + recipe.amount > itemDef.maxStack then
		return false, "Inventory full for this item"
	end

	-- Consume and craft
	consumeIngredients(inventory, recipe.ingredients)
	addToInventory(inventory, recipe.result, recipe.amount)

	-- Notify client of inventory update
	RemoteEvents.UpdateInventory:FireClient(player, inventory)

	print("[CraftingService]", player.Name, "crafted", recipe.amount, recipe.result)
	return true, "Crafted " .. recipe.result
end

print("[CraftingService] Crafting Service initialized.")
