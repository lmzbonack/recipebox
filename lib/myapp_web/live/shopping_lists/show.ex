defmodule MyappWeb.ShoppingListsLive.Show do
  use MyappWeb, :live_view
  alias Myapp.ShoppingLists

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    shopping_list = ShoppingLists.get_shopping_list!(id)

    {:ok,
     socket
     |> assign(shopping_list: shopping_list, page_title: shopping_list.name)
     |> push_event("init-checked-state", %{id: id})}
  end

  @impl true
  def handle_event("toggle-ingredient", %{"id" => ingredient_id}, socket) do
    {:noreply, push_event(socket, "update-checked-state", %{id: ingredient_id})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@shopping_list.name}
      <:actions>
        <.link patch={~p"/shopping-lists"}>
          <.button>Back to Shopping Lists</.button>
        </.link>
      </:actions>
    </.header>

    <div class="mt-10">
      <h2 class="text-lg font-semibold leading-8 text-zinc-800">Additional Ingredients</h2>
      <ul class="mt-4 space-y-2" id="additional-ingredients" phx-update="ignore">
        <%= if Enum.empty?(@shopping_list.ingredients) do %>
          <li class="text-zinc-600">No additional ingredients</li>
        <% else %>
          <%= for ingredient <- @shopping_list.ingredients do %>
            <li
              class="ingredient-item flex items-center space-x-3 text-zinc-600"
              data-id={"additional-#{ingredient}"}
            >
              <input
                type="checkbox"
                id={"check-#{ingredient}"}
                class="ingredient-checkbox h-4 w-4 rounded border-gray-300"
                phx-click="toggle-ingredient"
                phx-value-id={"additional-#{ingredient}"}
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
            <h3 class="text-md font-medium leading-8 text-zinc-700">{recipe.name}</h3>
            <ul class="mt-2 space-y-2" id={"recipe-#{recipe.id}-ingredients"} phx-update="ignore">
              <%= for ingredient <- recipe.ingredients do %>
                <li
                  class="ingredient-item flex items-center space-x-3 text-zinc-600"
                  data-id={"recipe-#{recipe.id}-#{ingredient}"}
                >
                  <input
                    type="checkbox"
                    id={"check-#{recipe.id}-#{ingredient}"}
                    class="ingredient-checkbox h-4 w-4 rounded border-gray-300"
                    phx-click="toggle-ingredient"
                    phx-value-id={"recipe-#{recipe.id}-#{ingredient}"}
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

    <script>
      window.addEventListener("phx:init-checked-state", (e) => {
        const listId = e.detail.id;
        const storageKey = `shopping-list-${listId}`;
        const checkedItems = JSON.parse(localStorage.getItem(storageKey) || "[]");

        // Apply checked state and move items
        checkedItems.forEach(id => {
          const checkbox = document.querySelector(`input[phx-value-id="${id}"]`);
          if (checkbox) {
            checkbox.checked = true;
            const item = checkbox.closest('.ingredient-item');
            item.style.opacity = "0.6";
            moveItemToBottom(item);
          }
        });
      });

      window.addEventListener("phx:update-checked-state", (e) => {
        const itemId = e.detail.id;
        const listId = window.location.pathname.split('/').pop();
        const storageKey = `shopping-list-${listId}`;
        const checkedItems = JSON.parse(localStorage.getItem(storageKey) || "[]");
        const checkbox = document.querySelector(`input[phx-value-id="${itemId}"]`);
        const item = checkbox.closest('.ingredient-item');

        if (checkbox.checked) {
          checkedItems.push(itemId);
          item.style.opacity = "0.6";
          moveItemToBottom(item);
        } else {
          const index = checkedItems.indexOf(itemId);
          if (index > -1) {
            checkedItems.splice(index, 1);
          }
          item.style.opacity = "1";
          moveItemToTop(item);
        }

        localStorage.setItem(storageKey, JSON.stringify(checkedItems));
      });

      function moveItemToBottom(item) {
        const parent = item.parentElement;
        parent.appendChild(item);
      }

      function moveItemToTop(item) {
        const parent = item.parentElement;
        parent.insertBefore(item, parent.firstChild);
      }
    </script>
    """
  end
end
