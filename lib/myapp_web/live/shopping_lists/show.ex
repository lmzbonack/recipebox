defmodule MyappWeb.ShoppingListsLive.Show do
  use MyappWeb, :live_view
  alias Myapp.ShoppingLists

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    shopping_list = ShoppingLists.get_shopping_list!(id)

    {:ok,
     socket
     |> assign(
       shopping_list: shopping_list,
       page_title: shopping_list.name,
       show_reset_modal: false
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit #{socket.assigns.shopping_list.name}")
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  @impl true
  def handle_info({MyappWeb.ShoppingListLive.FormComponent, {:saved, shopping_list}}, socket) do
    {:noreply,
     socket
     |> assign(shopping_list: ShoppingLists.get_shopping_list!(shopping_list.id))
     |> assign(page_title: shopping_list.name)}
  end

  @impl true
  def handle_event("toggle-ingredient", %{"id" => ingredient_id}, socket) do
    shopping_list = socket.assigns.shopping_list

    if ShoppingLists.can_edit_shopping_list?(socket.assigns.current_user, shopping_list) do
      {:ok, updated_list} = ShoppingLists.toggle_checked_ingredient(shopping_list, ingredient_id)

      {:noreply, socket |> assign(:shopping_list, updated_list)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("show-reset-modal", _, socket) do
    {:noreply, assign(socket, :show_reset_modal, true)}
  end

  @impl true
  def handle_event("hide-reset-modal", _, socket) do
    {:noreply, assign(socket, :show_reset_modal, false)}
  end

  @impl true
  def handle_event("reset-all", _, socket) do
    shopping_list = socket.assigns.shopping_list

    if ShoppingLists.can_edit_shopping_list?(socket.assigns.current_user, shopping_list) do
      {:ok, updated_list} = ShoppingLists.clear_checked_ingredients(shopping_list)

      {:noreply, socket |> assign(shopping_list: updated_list, show_reset_modal: false)}
    else
      {:noreply, assign(socket, :show_reset_modal, false)}
    end
  end

  @impl true
  def render(assigns) do
    checked = assigns.shopping_list.checked_ingredients || []

    assigns
    |> assign(:checked, checked)
    |> render_with_checked()
  end

  defp render_with_checked(assigns) do
    ~H"""
    <.header>
      {@shopping_list.name}
      <:actions>
        <%= if ShoppingLists.can_edit_shopping_list?(@current_user, @shopping_list) do %>
          <.link patch={~p"/shopping-lists/#{@shopping_list.id}/details/edit"}>
            <.button class="bg-yellow-500 text-black">Edit</.button>
          </.link>
          <.button phx-click="show-reset-modal" class="bg-red-500 text-white">
            Reset All
          </.button>
        <% end %>
        <.link patch={~p"/shopping-lists"}>
          <.button>Back to Shopping Lists</.button>
        </.link>
      </:actions>
    </.header>

    <.modal
      :if={@show_reset_modal}
      id="reset-confirm-modal"
      show
      on_cancel={JS.push("hide-reset-modal")}
    >
      <p class="text-zinc-600">Are you sure you want to uncheck all items?</p>
      <div class="mt-6 flex items-center gap-3">
        <.button phx-click="hide-reset-modal">Cancel</.button>
        <.button phx-click="reset-all" class="bg-red-500 text-white">Yes, Reset All</.button>
      </div>
    </.modal>

    <div class="mt-10">
      <h2 class="text-lg font-semibold leading-8 text-zinc-800">Additional Ingredients</h2>
      <ul class="mt-4 space-y-2" id="additional-ingredients">
        <%= if Enum.empty?(@shopping_list.ingredients) do %>
          <li class="text-zinc-600">No additional ingredients</li>
        <% else %>
          <%= for ingredient <- Enum.sort_by(@shopping_list.ingredients, fn i -> if i in @checked, do: 1, else: 0 end) do %>
            <% is_checked = ingredient in @checked %>
            <li
              class={"ingredient-item flex items-center space-x-3 #{if is_checked, do: "text-zinc-400 line-through", else: "text-zinc-600"}"}
              data-id={"additional-#{ingredient}"}
            >
              <input
                type="checkbox"
                id={"check-#{ingredient}"}
                class="ingredient-checkbox h-4 w-4 rounded border-gray-300"
                phx-click="toggle-ingredient"
                phx-value-id={"additional-#{ingredient}"}
                checked={is_checked}
              />
              <label for={"check-#{ingredient}"} class="ingredient-label flex-1">
                {ingredient}
              </label>
            </li>
          <% end %>
        <% end %>
      </ul>
    </div>

    <div class="mt-10">
      <h2 class="text-lg font-semibold leading-8 text-zinc-800">Recipe Ingredients</h2>
      <%= if Enum.empty?(@shopping_list.recipes) do %>
        <p class="mt-4 text-zinc-600">No recipes added to this shopping list</p>
      <% else %>
        <%= for recipe <- @shopping_list.recipes do %>
          <div class="mt-6">
            <h3 class="text-md font-medium leading-8 text-zinc-700">
              <.link navigate={~p"/recipes/#{recipe.id}"} class="hover:underline">
                {recipe.name}
              </.link>
            </h3>
            <ul class="mt-2 space-y-2" id={"recipe-#{recipe.id}-ingredients"}>
              <%= for ingredient <- Enum.sort_by(recipe.ingredients, fn i -> checked_id = "recipe-#{recipe.id}-#{i}"; if checked_id in @checked, do: 1, else: 0 end) do %>
                <% checked_id = "recipe-#{recipe.id}-#{ingredient}" %>
                <% is_checked = checked_id in @checked %>
                <li
                  class={"ingredient-item flex items-center space-x-3 #{if is_checked, do: "text-zinc-400 line-through", else: "text-zinc-600"}"}
                  data-id={checked_id}
                >
                  <input
                    type="checkbox"
                    id={"check-#{recipe.id}-#{ingredient}"}
                    class="ingredient-checkbox h-4 w-4 rounded border-gray-300"
                    phx-click="toggle-ingredient"
                    phx-value-id={checked_id}
                    checked={is_checked}
                  />
                  <label for={"check-#{recipe.id}-#{ingredient}"} class="ingredient-label flex-1">
                    {ingredient}
                  </label>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      <% end %>
    </div>

    <.back navigate={~p"/shopping-lists"}>Back to shopping lists</.back>

    <%= if @live_action == :edit do %>
      <.modal
        :if={@shopping_list}
        id="shopping-list-modal"
        show
        on_cancel={JS.patch(~p"/shopping-lists/#{@shopping_list.id}")}
      >
        <.live_component
          module={MyappWeb.ShoppingListLive.FormComponent}
          id={@shopping_list.id}
          title={@page_title}
          action={@live_action}
          shopping_list={@shopping_list}
          patch={~p"/shopping-lists/#{@shopping_list.id}"}
          current_user={@current_user}
        />
      </.modal>
    <% end %>
    """
  end
end
