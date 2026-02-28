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
      assert recipe.author == "Chef John"
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

    test "search_recipes/1 returns recipes matching name" do
      user = user_fixture()

      recipe_attrs = %{
        name: "Chocolate Cake",
        author: "Chef John",
        prep_time_in_minutes: 30,
        cook_time_in_minutes: 45,
        ingredients: ["flour", "sugar", "cocoa"],
        instructions: ["Mix", "Bake"]
      }

      {:ok, _recipe} = Recipes.create_recipe(recipe_attrs, user)

      results = Recipes.search_recipes("chocolate")
      assert length(results) == 1
      assert hd(results).name == "Chocolate Cake"
    end

    test "search_recipes/1 returns recipes matching author" do
      user = user_fixture()

      recipe_attrs = %{
        name: "Some Recipe",
        author: "Gordon Ramsay",
        prep_time_in_minutes: 30,
        cook_time_in_minutes: 45,
        ingredients: ["ingredient"],
        instructions: ["step"]
      }

      {:ok, _recipe} = Recipes.create_recipe(recipe_attrs, user)

      results = Recipes.search_recipes("gordon")
      assert length(results) == 1
      assert hd(results).author == "Gordon Ramsay"
    end

    test "search_recipes/1 returns recipes matching ingredients" do
      user = user_fixture()

      recipe_attrs = %{
        name: "Pasta Carbonara",
        author: "Chef Mario",
        prep_time_in_minutes: 15,
        cook_time_in_minutes: 20,
        ingredients: ["spaghetti", "eggs", "bacon", "parmesan"],
        instructions: ["Cook pasta", "Mix eggs and cheese"]
      }

      {:ok, _recipe} = Recipes.create_recipe(recipe_attrs, user)

      results = Recipes.search_recipes("bacon")
      assert length(results) == 1
      assert "bacon" in hd(results).ingredients
    end

    test "search_recipes/1 returns empty list for empty query" do
      assert Recipes.search_recipes("") == []
      assert Recipes.search_recipes(nil) == []
    end

    test "search_recipes/1 is case insensitive" do
      user = user_fixture()

      recipe_attrs = %{
        name: "ITALIAN PASTA",
        author: "Chef Luigi",
        prep_time_in_minutes: 15,
        cook_time_in_minutes: 20,
        ingredients: ["pasta"],
        instructions: ["Cook"]
      }

      {:ok, _recipe} = Recipes.create_recipe(recipe_attrs, user)

      results = Recipes.search_recipes("italian")
      assert length(results) == 1

      results = Recipes.search_recipes("PASTA")
      assert length(results) == 1
    end

    test "search_recipes/1 returns multiple matching recipes" do
      user = user_fixture()

      attrs1 = %{
        name: "Chocolate Chip Cookies",
        author: "Chef John",
        prep_time_in_minutes: 20,
        cook_time_in_minutes: 12,
        ingredients: ["chocolate", "flour", "sugar"],
        instructions: ["Mix", "Bake"]
      }

      attrs2 = %{
        name: "Chocolate Cake",
        author: "Chef Jane",
        prep_time_in_minutes: 30,
        cook_time_in_minutes: 45,
        ingredients: ["chocolate", "flour", "eggs"],
        instructions: ["Mix", "Bake"]
      }

      {:ok, _recipe1} = Recipes.create_recipe(attrs1, user)
      {:ok, _recipe2} = Recipes.create_recipe(attrs2, user)

      results = Recipes.search_recipes("chocolate")
      assert length(results) == 2
    end

    test "search_recipes/1 returns empty list when no matches" do
      user = user_fixture()

      recipe_attrs = %{
        name: "Pasta",
        author: "Chef",
        prep_time_in_minutes: 15,
        cook_time_in_minutes: 20,
        ingredients: ["pasta"],
        instructions: ["Cook"]
      }

      {:ok, _recipe} = Recipes.create_recipe(recipe_attrs, user)

      results = Recipes.search_recipes("nonexistent")
      assert results == []
    end
  end
end
