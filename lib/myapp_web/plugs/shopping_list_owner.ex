defmodule MyappWeb.Plugs.ShoppingListOwner do
  use MyappWeb, :verified_routes
  import Plug.Conn
  import Phoenix.Controller
  alias Myapp.ShoppingLists

  def init(opts), do: opts

  def call(conn, _opts) do
    with %{"id" => id} <- conn.path_params,
         shopping_list when not is_nil(shopping_list) <- ShoppingLists.get_shopping_list(id),
         %{current_user: current_user} when not is_nil(current_user) <- conn.assigns do
      if shopping_list.created_by_id == current_user.id do
        conn
      else
        conn
        |> put_flash(:error, "You can only edit shopping list you created")
        |> redirect(to: ~p"/shopping-lists")
        |> halt()
      end
    else
      _ ->
        conn
        |> put_flash(:error, "Shopping list not found")
        |> redirect(to: ~p"/shopping-lists")
        |> halt()
    end
  end
end
