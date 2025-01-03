defmodule MyappWeb.Plugs.RecipeOwner do
  use MyappWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller
  alias Myapp.Recipes

  def init(opts), do: opts

  def call(conn, _opts) do
    with %{"id" => id} <- conn.path_params,
         recipe when not is_nil(recipe) <- Recipes.get_recipe(id),
         %{current_user: current_user} when not is_nil(current_user) <- conn.assigns do
      if recipe.created_by_id == current_user.id do
        conn
      else
        conn
        |> put_flash(:error, "You can only edit recipes you created")
        |> redirect(to: ~p"/recipes")
        |> halt()
      end
    else
      _ ->
        conn
        |> put_flash(:error, "Recipe not found")
        |> redirect(to: ~p"/recipes")
        |> halt()
    end
  end
end
