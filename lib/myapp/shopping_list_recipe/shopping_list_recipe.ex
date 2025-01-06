defmodule Myapp.ShoppingListRecipe.ShoppingListRecipe do
  use Ecto.Schema

  @primary_key false
  schema "shopping_lists_recipes" do
    belongs_to :shopping_list, Myapp.ShoppingLists.ShoppingList
    belongs_to :recipe, Myapp.Recipes.Recipe

    timestamps(type: :utc_datetime)
  end
end
