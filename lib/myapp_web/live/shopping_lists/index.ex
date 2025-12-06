defmodule MyappWeb.ShoppingListsLive.Index do
  use MyappWeb, :live_view

  alias Myapp.ShoppingLists
  alias Myapp.ShoppingLists.ShoppingList

  @impl true
  def mount(_params, _session, socket) do
    shopping_lists = ShoppingLists.list_user_shopping_lists(socket.assigns.current_user)
    {:ok, assign(socket, :shopping_lists, shopping_lists)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Shopping List")
    |> assign(:shopping_list, %ShoppingList{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Shopping List")
    |> assign(:shopping_list, ShoppingLists.get_shopping_list!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Shopping Lists")
    |> assign(:shopping_list, nil)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Your Shopping Lists")
  end

  @impl true
  def handle_event("delete_shopping_list", %{"id" => id}, socket) do
    sl = ShoppingLists.get_shopping_list!(id)
    {:ok, _} = ShoppingLists.delete_shopping_list(sl)

    {:noreply,
     socket
     |> put_flash(:info, "Shopping List deleted successfully")
     |> assign(
       :shopping_lists,
       ShoppingLists.list_user_shopping_lists(socket.assigns.current_user)
     )}
  end

  @impl true
  def handle_info({MyappWeb.ShoppingListLive.FormComponent, {:saved, shopping_list}}, socket) do
    updated_sl = ShoppingLists.get_shopping_list!(shopping_list.id)

    updated_sls =
      Enum.map(socket.assigns.shopping_lists, fn s ->
        if s.id == shopping_list.id, do: updated_sl, else: s
      end)

    {:noreply,
     socket
     |> assign(:shopping_lists, updated_sls)}
  end

  @impl true
  def handle_info({MyappWeb.ShoppingListLive.FormComponent, {:created, shopping_list}}, socket) do
    updated_sl = ShoppingLists.get_shopping_list!(shopping_list.id)

    {:noreply,
     socket
     |> assign(:shopping_lists, [updated_sl | socket.assigns.shopping_lists])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:actions>
        <.link
          patch={~p"/shopping-lists/new"}
          class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
        >
          New Shopping List
        </.link>
      </:actions>
    </.header>

    <.table
      id="shopping-lists"
      rows={@shopping_lists}
      row_click={fn shopping_list -> JS.navigate(~p"/shopping-lists/#{shopping_list.id}") end}
    >
      <:col :let={shopping_list} label="Name">{shopping_list.name}</:col>
      <:action :let={shopping_list}>
        <.link patch={~p"/shopping-lists/#{shopping_list.id}/edit"}>Edit</.link>
      </:action>
      <:action :let={shopping_list}>
        <.button
          phx-click="delete_shopping_list"
          phx-value-id={shopping_list.id}
          class="bg-red-500 text-white"
          data-confirm="Are you sure you want to delete this shopping list?"
        >
          Delete
        </.button>
      </:action>
    </.table>

    <%= if @live_action in [:new, :edit] do %>
      <.modal
        :if={@shopping_list}
        id="shopping-list-modal"
        show
        on_cancel={JS.patch(~p"/shopping-lists")}
      >
        <.live_component
          module={MyappWeb.ShoppingListLive.FormComponent}
          id={@shopping_list.id || :new}
          title={@page_title}
          action={@live_action}
          shopping_list={@shopping_list}
          patch={~p"/shopping-lists"}
          current_user={@current_user}
        />
      </.modal>
    <% end %>
    """
  end
end
