defmodule MyappWeb.PageController do
  use MyappWeb, :controller

  alias Myapp.Recipes

  def home(conn, _params) do
    user = get_session(conn, :user)
    newest_recipes = Recipes.list_newest(5)
    render(conn, "home.html", layout: false, user: user, recipes: newest_recipes)
  end
end
