-- RecipeData.lua
-- Defines all crafting recipes

local RecipeData = {}

RecipeData.Recipes = {
	{
		result = "axe",
		amount = 1,
		ingredients = {
			wood = 2,
			stone = 1,
		},
	},
	{
		result = "pickaxe",
		amount = 1,
		ingredients = {
			wood = 1,
			stone = 2,
		},
	},
	{
		result = "wall",
		amount = 1,
		ingredients = {
			wood = 4,
		},
	},
	{
		result = "floor",
		amount = 1,
		ingredients = {
			wood = 2,
		},
	},
	{
		result = "campfire",
		amount = 1,
		ingredients = {
			wood = 3,
			stone = 1,
		},
	},
}

-- Helper: find recipe by result item id
function RecipeData.GetRecipeForItem(itemId)
	for _, recipe in ipairs(RecipeData.Recipes) do
		if recipe.result == itemId then
			return recipe
		end
	end
	return nil
end

return RecipeData
