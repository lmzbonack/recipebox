defmodule MyappWeb.RecipeLive.ShowTest do
  use MyappWeb.ConnCase

  import Phoenix.LiveViewTest
  import Myapp.AccountsFixtures

  alias Myapp.Recipes
  alias Myapp.ShoppingLists

  setup do
    user = user_fixture()
    other_user = user_fixture()

    recipe_attrs = %{
      name: "Test Recipe",
      author: "Test Author",
      prep_time_in_minutes: 30,
      cook_time_in_minutes: 45,
      ingredients: ["ingredient 1", "ingredient 2"],
      instructions: ["step 1", "step 2"]
    }

    {:ok, recipe} = Recipes.create_recipe(recipe_attrs, user)

    %{user: user, other_user: other_user, recipe: recipe}
  end

  describe "recipe show page" do
    test "renders recipe details", %{conn: conn, user: user, recipe: recipe} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      assert html =~ recipe.name
      assert html =~ recipe.author
      assert html =~ "30 minutes"
      assert html =~ "45 minutes"
      assert html =~ "ingredient 1"
      assert html =~ "step 1"
    end

    test "shows add to shopping list button for all users", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      assert has_element?(lv, "#add-to-shopping-list")
      assert render(lv) =~ "Add to Shopping List"
    end

    test "opens shopping list modal when add to shopping list button is clicked", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, shopping_list} =
        ShoppingLists.create_shopping_list(%{name: "My Shopping List", ingredients: []}, user)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Click the add to shopping list button and wait for patch
      lv
      |> element("#add-to-shopping-list")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}?action=add_to_shopping_list")

      # Verify modal is shown
      assert has_element?(lv, "#select-shopping-list-modal")
      assert render(lv) =~ "Select a Shopping List"
      assert render(lv) =~ shopping_list.name
    end

    test "shows empty state when user has no shopping lists", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Click the add to shopping list button and wait for patch
      lv
      |> element("#add-to-shopping-list")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}?action=add_to_shopping_list")

      # Verify modal is shown
      assert has_element?(lv, "#select-shopping-list-modal")

      # Check modal content by finding the modal element
      modal_html =
        lv
        |> element("#select-shopping-list-modal")
        |> render()

      assert modal_html =~ "Select a Shopping List"
      # Check for empty state message (HTML encoded apostrophe)
      assert modal_html =~ "don" && modal_html =~ "have any shopping lists yet"
      assert modal_html =~ "Create a new shopping list"
    end

    test "adds recipe to shopping list when a list is selected", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, shopping_list} =
        ShoppingLists.create_shopping_list(%{name: "My Shopping List", ingredients: []}, user)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Open the modal
      lv
      |> element("#add-to-shopping-list")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}?action=add_to_shopping_list")

      # Select a shopping list
      lv
      |> element("button[phx-click='select_shopping_list'][phx-value-id='#{shopping_list.id}']")
      |> render_click()

      # Verify patch back to recipe page
      assert_patch(lv, ~p"/recipes/#{recipe.id}")

      # Verify recipe was added to shopping list
      updated_list = ShoppingLists.get_shopping_list!(shopping_list.id)
      assert length(updated_list.recipes) == 1
      assert hd(updated_list.recipes).id == recipe.id
    end

    test "shows success flash message when recipe is added to shopping list", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, shopping_list} =
        ShoppingLists.create_shopping_list(%{name: "My Shopping List", ingredients: []}, user)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Open the modal
      lv
      |> element("#add-to-shopping-list")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}?action=add_to_shopping_list")

      # Select a shopping list
      lv
      |> element("button[phx-click='select_shopping_list'][phx-value-id='#{shopping_list.id}']")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}")

      # Verify flash message
      assert render(lv) =~ "Recipe added to My Shopping List successfully"
    end

    test "modal can be closed by navigating back", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, _shopping_list} =
        ShoppingLists.create_shopping_list(%{name: "My Shopping List", ingredients: []}, user)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Open the modal
      lv
      |> element("#add-to-shopping-list")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}?action=add_to_shopping_list")
      assert has_element?(lv, "#select-shopping-list-modal")

      # Navigate back to recipe page without action parameter
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Verify modal is closed
      refute has_element?(lv, "#select-shopping-list-modal")
    end

    test "only shows user's own shopping lists in modal", %{
      conn: conn,
      user: user,
      other_user: other_user,
      recipe: recipe
    } do
      {:ok, _user_list} =
        ShoppingLists.create_shopping_list(%{name: "User's List", ingredients: []}, user)

      {:ok, _other_list} =
        ShoppingLists.create_shopping_list(
          %{name: "Other User's List", ingredients: []},
          other_user
        )

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Open the modal
      lv
      |> element("#add-to-shopping-list")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}?action=add_to_shopping_list")

      # Verify modal is shown
      assert has_element?(lv, "#select-shopping-list-modal")

      # Check modal content
      modal_html =
        lv
        |> element("#select-shopping-list-modal")
        |> render()

      assert modal_html =~ "Select a Shopping List"
      # Check for user's list (HTML encoded apostrophe)
      assert modal_html =~ "User" && modal_html =~ "List"
      # Verify other user's list is not shown
      refute modal_html =~ "Other User"
    end

    test "handles multiple shopping lists correctly", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, list1} =
        ShoppingLists.create_shopping_list(%{name: "List 1", ingredients: []}, user)

      {:ok, list2} =
        ShoppingLists.create_shopping_list(%{name: "List 2", ingredients: []}, user)

      {:ok, list3} =
        ShoppingLists.create_shopping_list(%{name: "List 3", ingredients: []}, user)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}")

      # Open the modal
      lv
      |> element("#add-to-shopping-list")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}?action=add_to_shopping_list")

      html = render(lv)
      assert html =~ "List 1"
      assert html =~ "List 2"
      assert html =~ "List 3"

      # Select one list
      lv
      |> element("button[phx-click='select_shopping_list'][phx-value-id='#{list2.id}']")
      |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}")

      # Verify recipe was added to the selected list
      updated_list = ShoppingLists.get_shopping_list!(list2.id)
      assert length(updated_list.recipes) == 1
      assert hd(updated_list.recipes).id == recipe.id

      # Verify other lists are unchanged
      list1_updated = ShoppingLists.get_shopping_list!(list1.id)
      list3_updated = ShoppingLists.get_shopping_list!(list3.id)
      assert Enum.empty?(list1_updated.recipes)
      assert Enum.empty?(list3_updated.recipes)
    end

    test "modal opens with correct query parameter", %{
      conn: conn,
      user: user,
      recipe: recipe
    } do
      {:ok, _shopping_list} =
        ShoppingLists.create_shopping_list(%{name: "My Shopping List", ingredients: []}, user)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}?action=add_to_shopping_list")

      # Verify modal is shown immediately
      assert has_element?(lv, "#select-shopping-list-modal")
      assert render(lv) =~ "Select a Shopping List"
    end

    test "redirects to login if user is not authenticated", %{conn: conn, recipe: recipe} do
      assert {:error, redirect} = live(conn, ~p"/recipes/#{recipe.id}")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert flash["error"] == "You must log in to access this page."
    end
  end
end
