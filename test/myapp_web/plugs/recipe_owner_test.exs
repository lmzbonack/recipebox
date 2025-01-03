defmodule MyappWeb.Plugs.RecipeOwnerTest do
  use MyappWeb.ConnCase
  import Myapp.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Myapp.Recipes

  setup do
    owner = user_fixture()
    other_user = user_fixture()

    recipe_attrs = %{
      name: "Test Recipe",
      author: "Test Author",
      prep_time_in_minutes: 30,
      cook_time_in_minutes: 45,
      ingredients: ["ingredient 1", "ingredient 2"],
      instructions: ["step 1", "step 2"]
    }

    {:ok, recipe} = Recipes.create_recipe(recipe_attrs, owner)

    %{owner: owner, other_user: other_user, recipe: recipe}
  end

  describe "recipe ownership" do
    test "allows owner to edit their recipe", %{conn: conn, owner: owner, recipe: recipe} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/recipes/#{recipe.id}/edit")

      assert has_element?(lv, "form#recipe-form")
    end

    test "redirects non-owner when trying to edit recipe", %{
      conn: conn,
      other_user: other_user,
      recipe: recipe
    } do
      {:error, {:redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(other_user)
        |> live(~p"/recipes/#{recipe.id}/edit")

      assert path == ~p"/recipes"
      assert flash["error"] == "You can only edit recipes you created"
    end

    test "redirects when recipe doesn't exist", %{conn: conn, owner: owner} do
      {:error, {:redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(owner)
        |> live(~p"/recipes/999999/edit")

      assert path == ~p"/recipes"
      assert flash["error"] == "Recipe not found"
    end

    test "redirects when user is not authenticated", %{conn: conn, recipe: recipe} do
      assert {:error, {:redirect, %{to: path, flash: flash}}} =
               live(conn, ~p"/recipes/#{recipe.id}/edit")

      assert path == ~p"/users/log_in"
      assert flash["error"] == "You must log in to access this page."
    end

    test "allows owner to edit recipe details", %{conn: conn, owner: owner, recipe: recipe} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(owner)
        |> live(~p"/recipes/#{recipe.id}/details/edit")

      assert has_element?(lv, "form#recipe-form")
    end

    test "redirects non-owner when trying to edit recipe details", %{
      conn: conn,
      other_user: other_user,
      recipe: recipe
    } do
      {:error, {:redirect, %{to: path, flash: flash}}} =
        conn
        |> log_in_user(other_user)
        |> live(~p"/recipes/#{recipe.id}/details/edit")

      assert path == ~p"/recipes"
      assert flash["error"] == "You can only edit recipes you created"
    end
  end
end
