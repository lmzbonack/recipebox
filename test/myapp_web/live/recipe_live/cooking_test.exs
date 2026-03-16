defmodule MyappWeb.RecipeLive.CookingTest do
  use MyappWeb.ConnCase

  import Phoenix.LiveViewTest
  import Myapp.AccountsFixtures

  alias Myapp.Recipes

  setup do
    user = user_fixture()

    recipe = %{
      name: "Test Recipe",
      author: "Test Author",
      prep_time_in_minutes: 10,
      cook_time_in_minutes: 20,
      ingredients: [
        "2 cups flour",
        "1 cup butter"
      ],
      instructions: ["Mix", "Bake"]
    }

    {:ok, recipe} = Recipes.create_recipe(recipe, user)
    %{user: user, recipe: recipe}
  end

  describe "cooking view" do
    test "renders the cooking view", %{conn: conn, user: user, recipe: recipe} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}/cook")

      assert html =~ "Cooking: Test Recipe"
      assert html =~ "Test Recipe"
      assert html =~ "Test Author"
      assert html =~ "2 cups flour"
      assert html =~ "1 cup butter"
    end

    test "renders scale buttons", %{conn: conn, user: user, recipe: recipe} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}/cook")

      assert has_element?(lv, "button", "1x")
      assert has_element?(lv, "button", "2x")
      assert has_element?(lv, "button", "3x")
      assert has_element?(lv, "button", "4x")
    end

    test "clicking 2x updates URL", %{conn: conn, user: user, recipe: recipe} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}/cook")

      lv |> element("button", "2x") |> render_click()

      assert_patch(lv, ~p"/recipes/#{recipe.id}/cook?scale=2")
    end

    test "back link navigates to recipe", %{conn: conn, user: user, recipe: recipe} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes/#{recipe.id}/cook")

      lv |> element("a", "Back to recipe") |> render_click()
      assert_redirect(lv, ~p"/recipes/#{recipe.id}")
    end
  end
end
