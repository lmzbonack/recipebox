defmodule Myapp.RecipesTest do
  use Myapp.DataCase

  alias Myapp.Recipes
  import Myapp.AccountsFixtures

  describe "recipes" do
    alias Myapp.Recipes.Recipe

    @valid_attrs %{
      name: "Classic Chocolate Chip Cookies",
      author: "Chef John",
      prep_time_in_minutes: 20,
      cook_time_in_minutes: 12,
      ingredients: [
        "2 1/4 cups all-purpose flour",
        "1 cup butter, softened",
        "2 eggs"
      ],
      instructions: [
        "Preheat oven to 375°F",
        "Mix ingredients",
        "Bake for 12 minutes"
      ]
    }
    @update_attrs %{
      name: "Updated Cookie Recipe",
      author: "Chef Jane",
      prep_time_in_minutes: 25,
      cook_time_in_minutes: 15,
      ingredients: ["Updated ingredient 1", "Updated ingredient 2"],
      instructions: ["Updated step 1", "Updated step 2"]
    }
    @invalid_attrs %{name: nil, author: nil, ingredients: nil, instructions: nil}

    setup do
      user = user_fixture()
      %{user: user}
    end

    test "list_recipes/0 returns all recipes", %{user: user} do
      {:ok, recipe} = Recipes.create_recipe(@valid_attrs, user)
      assert Recipes.list_recipes() == [recipe]
    end

    test "get_recipe!/1 returns the recipe with given id", %{user: user} do
      {:ok, recipe} = Recipes.create_recipe(@valid_attrs, user)
      assert Recipes.get_recipe!(recipe.id) == recipe
    end

    test "create_recipe/2 with valid data creates a recipe", %{user: user} do
      assert {:ok, %Recipe{} = recipe} = Recipes.create_recipe(@valid_attrs, user)
      assert recipe.name == "Classic Chocolate Chip Cookies"
      assert recipe.author == "Chef Joh"
      assert recipe.prep_time_in_minutes == 20
      assert recipe.cook_time_in_minutes == 12
      assert length(recipe.ingredients) == 3
      assert length(recipe.instructions) == 3
      assert recipe.created_by_id == user.id
    end

    test "create_recipe/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Recipes.create_recipe(@invalid_attrs, user)
    end

    test "update_recipe/2 with valid data updates the recipe", %{user: user} do
      {:ok, recipe} = Recipes.create_recipe(@valid_attrs, user)
      assert {:ok, %Recipe{} = recipe} = Recipes.update_recipe(recipe, @update_attrs)
      assert recipe.name == "Updated Cookie Recipe"
      assert recipe.author == "Chef Jane"
      assert recipe.prep_time_in_minutes == 25
      assert recipe.cook_time_in_minutes == 15
      assert recipe.ingredients == ["Updated ingredient 1", "Updated ingredient 2"]
      assert recipe.instructions == ["Updated step 1", "Updated step 2"]
    end

    test "update_recipe/2 with invalid data returns error changeset", %{user: user} do
      {:ok, recipe} = Recipes.create_recipe(@valid_attrs, user)
      assert {:error, %Ecto.Changeset{}} = Recipes.update_recipe(recipe, @invalid_attrs)
      assert recipe == Recipes.get_recipe!(recipe.id)
    end

    test "delete_recipe/1 deletes the recipe", %{user: user} do
      {:ok, recipe} = Recipes.create_recipe(@valid_attrs, user)
      assert {:ok, %Recipe{}} = Recipes.delete_recipe(recipe)
      assert_raise Ecto.NoResultsError, fn -> Recipes.get_recipe!(recipe.id) end
    end

    test "list_user_recipes/1 returns all recipes for a user", %{user: user} do
      {:ok, recipe1} = Recipes.create_recipe(@valid_attrs, user)
      {:ok, recipe2} = Recipes.create_recipe(@update_attrs, user)

      other_user = user_fixture()
      other_recipe_attrs = %{@valid_attrs | name: "New Recipe Name"}
      {:ok, _other_recipe} = Recipes.create_recipe(other_recipe_attrs, other_user)

      user_recipes = Recipes.list_user_recipes(user)
      assert length(user_recipes) == 2
      assert Enum.all?(user_recipes, fn r -> r.created_by_id == user.id end)
      assert recipe1 in user_recipes
      assert recipe2 in user_recipes
    end
  end
end
