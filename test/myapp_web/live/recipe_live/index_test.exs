defmodule MyappWeb.RecipeLive.IndexTest do
  use MyappWeb.ConnCase

  import Phoenix.LiveViewTest
  import Myapp.AccountsFixtures

  alias Myapp.Recipes

  setup do
    user = user_fixture()

    recipe_attrs = %{
      name: "Chocolate Chip Cookies",
      author: "Chef John",
      prep_time_in_minutes: 20,
      cook_time_in_minutes: 12,
      ingredients: ["flour", "sugar", "chocolate chips"],
      instructions: ["Mix", "Bake"]
    }

    {:ok, recipe} = Recipes.create_recipe(recipe_attrs, user)

    %{user: user, recipe: recipe}
  end

  describe "recipe index page" do
    test "renders recipe list", %{conn: conn, user: user, recipe: recipe} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      assert html =~ "Recipes"
      assert html =~ recipe.name
      assert html =~ recipe.author
    end

    test "shows search input", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      assert has_element?(lv, "input[name=\"search\"]")
    end

    test "search filters recipes by name", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      render_hook(lv, "search", %{"search" => "chocolate"})

      assert render(lv) =~ "Chocolate Chip Cookies"
    end

    test "search shows results when no matches", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      render_hook(lv, "search", %{"search" => "nonexistent123"})

      html = render(lv)
      assert html =~ "nonexistent123"
    end

    test "clear search returns to full list", %{conn: conn, user: user, recipe: recipe} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      render_hook(lv, "search", %{"search" => "chocolate"})

      assert render(lv) =~ "Chocolate Chip Cookies"

      lv
      |> element("a", "Clear search")
      |> render_click()

      assert render(lv) =~ recipe.name
      refute render(lv) =~ "Showing results for"
    end

    test "search is global (returns all users' recipes)", %{conn: conn, user: user} do
      other_user = user_fixture()

      other_recipe_attrs = %{
        name: "Pasta Carbonara",
        author: "Chef Mario",
        prep_time_in_minutes: 15,
        cook_time_in_minutes: 20,
        ingredients: ["pasta", "eggs", "bacon"],
        instructions: ["Cook pasta"]
      }

      {:ok, _other_recipe} = Recipes.create_recipe(other_recipe_attrs, other_user)

      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      render_hook(lv, "search", %{"search" => "pasta"})

      assert render(lv) =~ "Pasta Carbonara"
    end

    test "search by author", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      render_hook(lv, "search", %{"search" => "chef"})

      assert render(lv) =~ "Chef John"
    end

    test "search by ingredient", %{conn: conn, user: user} do
      {:ok, lv, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/recipes")

      render_hook(lv, "search", %{"search" => "flour"})

      assert render(lv) =~ "Chocolate Chip Cookies"
    end
  end
end
