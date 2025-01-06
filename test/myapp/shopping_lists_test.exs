defmodule Myapp.ShoppingListsTest do
  use Myapp.DataCase

  alias Myapp.ShoppingLists
  alias Myapp.Recipes
  import Myapp.AccountsFixtures

  describe "shopping_lists" do
    alias Myapp.ShoppingLists.ShoppingList

    @valid_attrs %{
      name: "Weekly Groceries",
      ingredients: ["Milk", "Eggs", "Bread"]
    }
    @update_attrs %{
      name: "Updated Shopping List",
      ingredients: ["Updated item 1", "Updated item 2"]
    }
    @invalid_attrs %{name: nil, ingredients: nil}

    setup do
      user = user_fixture()
      %{user: user}
    end

    test "get_shopping_list!/1 returns the shopping list with given id", %{user: user} do
      {:ok, shopping_list} = ShoppingLists.create_shopping_list(@valid_attrs, user)
      shopping_list = Repo.preload(shopping_list, :recipes)
      assert ShoppingLists.get_shopping_list!(shopping_list.id) == shopping_list
    end

    test "create_shopping_list/2 with valid data creates a shopping list", %{user: user} do
      assert {:ok, %ShoppingList{} = shopping_list} =
               ShoppingLists.create_shopping_list(@valid_attrs, user)

      assert shopping_list.name == "Weekly Groceries"
      assert shopping_list.ingredients == ["Milk", "Eggs", "Bread"]
      assert shopping_list.created_by_id == user.id
    end

    test "create_shopping_list/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} =
               ShoppingLists.create_shopping_list(@invalid_attrs, user)
    end

    test "update_shopping_list/2 with valid data updates the shopping list", %{user: user} do
      {:ok, shopping_list} = ShoppingLists.create_shopping_list(@valid_attrs, user)

      assert {:ok, %ShoppingList{} = shopping_list} =
               ShoppingLists.update_shopping_list(shopping_list, @update_attrs)

      assert shopping_list.name == "Updated Shopping List"
      assert shopping_list.ingredients == ["Updated item 1", "Updated item 2"]
    end

    test "update_shopping_list/2 with invalid data returns error changeset", %{user: user} do
      {:ok, shopping_list} = ShoppingLists.create_shopping_list(@valid_attrs, user)
      shopping_list = Repo.preload(shopping_list, :recipes)

      assert {:error, %Ecto.Changeset{}} =
               ShoppingLists.update_shopping_list(shopping_list, @invalid_attrs)

      assert shopping_list == ShoppingLists.get_shopping_list!(shopping_list.id)
    end

    test "delete_shopping_list/1 deletes the shopping list", %{user: user} do
      {:ok, shopping_list} = ShoppingLists.create_shopping_list(@valid_attrs, user)
      assert {:ok, %ShoppingList{}} = ShoppingLists.delete_shopping_list(shopping_list)

      assert_raise Ecto.NoResultsError, fn ->
        ShoppingLists.get_shopping_list!(shopping_list.id)
      end
    end

    test "list_user_shopping_lists/1 returns all shopping lists for a user", %{user: user} do
      {:ok, list1} = ShoppingLists.create_shopping_list(@valid_attrs, user)
      {:ok, list2} = ShoppingLists.create_shopping_list(@update_attrs, user)

      list1 = Repo.preload(list1, :recipes)
      list2 = Repo.preload(list2, :recipes)

      other_user = user_fixture()
      other_list_attrs = %{@valid_attrs | name: "Other User's List"}
      {:ok, _other_list} = ShoppingLists.create_shopping_list(other_list_attrs, other_user)

      user_lists = ShoppingLists.list_user_shopping_lists(user)
      assert length(user_lists) == 2
      assert Enum.all?(user_lists, fn l -> l.created_by_id == user.id end)
      assert list1 in user_lists
      assert list2 in user_lists
    end

    test "add_recipe_to_shopping_list/2 adds a recipe to shopping list", %{user: user} do
      {:ok, shopping_list} = ShoppingLists.create_shopping_list(@valid_attrs, user)

      recipe_attrs = %{
        name: "Test Recipe",
        author: "Test Author",
        prep_time_in_minutes: 30,
        cook_time_in_minutes: 45,
        ingredients: ["ingredient 1", "ingredient 2"],
        instructions: ["step 1", "step 2"]
      }

      {:ok, recipe} = Recipes.create_recipe(recipe_attrs, user)

      assert {:ok, updated_list} =
               ShoppingLists.add_recipe_to_shopping_list(shopping_list, recipe)

      assert length(updated_list.recipes) == 1
      assert hd(updated_list.recipes).id == recipe.id
    end

    test "remove_recipe_from_shopping_list/2 removes a recipe from shopping list", %{user: user} do
      {:ok, shopping_list} = ShoppingLists.create_shopping_list(@valid_attrs, user)

      recipe_attrs = %{
        name: "Test Recipe",
        author: "Test Author",
        prep_time_in_minutes: 30,
        cook_time_in_minutes: 45,
        ingredients: ["ingredient 1", "ingredient 2"],
        instructions: ["step 1", "step 2"]
      }

      {:ok, recipe} = Recipes.create_recipe(recipe_attrs, user)
      {:ok, list_with_recipe} = ShoppingLists.add_recipe_to_shopping_list(shopping_list, recipe)

      assert {:ok, updated_list} =
               ShoppingLists.remove_recipe_from_shopping_list(list_with_recipe, recipe)

      assert Enum.empty?(updated_list.recipes)
    end
  end
end
