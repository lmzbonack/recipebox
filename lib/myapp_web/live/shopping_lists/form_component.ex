defmodule MyappWeb.ShoppingListLive.FormComponent do
  use MyappWeb, :live_component

  alias Myapp.ShoppingLists

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="shopping-list-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />

        <%= if @action == :edit && length(@recipes) > 0 do %>
          <div class="space-y-2 mt-6">
            <label class="block text-sm font-semibold leading-6 text-zinc-800">
              Linked Recipes
            </label>

            <div
              :for={recipe <- @recipes}
              class="flex items-center justify-between p-3 border border-zinc-200 rounded-lg"
            >
              <span class="text-sm text-zinc-700">{recipe.name}</span>
              <button
                type="button"
                phx-click="remove_recipe"
                phx-value-recipe-id={recipe.id}
                phx-target={@myself}
                data-confirm="Are you sure you want to remove this recipe?"
                class="px-2 py-1 text-sm text-red-600 hover:text-red-700"
              >
                Remove
              </button>
            </div>
          </div>
        <% end %>

        <div class="space-y-2">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Additional Ingredients
          </label>

          <div :for={{ingredient, i} <- Enum.with_index(@ingredients)} class="flex items-center gap-2">
            <div class="flex-1">
              <.input
                field={@form[:ingredient]}
                name={"ingredient-#{i}"}
                type="text"
                value={ingredient}
                phx-target={@myself}
                phx-change="update_ingredient"
                phx-value-index={i}
              />
            </div>
            <button
              type="button"
              phx-click="remove_ingredient"
              phx-value-index={i}
              phx-target={@myself}
              class="px-2 py-1 text-sm text-red-600 hover:text-red-700 whitespace-nowrap"
            >
              Remove
            </button>
          </div>

          <div class="flex justify-end">
            <.button
              type="button"
              phx-click="add_ingredient"
              phx-target={@myself}
              class="bg-green-500 text-black"
            >
              Add Ingredient
            </.button>
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Shopping List</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def update(%{shopping_list: shopping_list} = assigns, socket) do
    changeset = ShoppingLists.change_shopping_list(shopping_list)

    {ingredients, recipes} =
      if shopping_list.id do
        loaded_list = ShoppingLists.get_shopping_list!(shopping_list.id)
        {loaded_list.ingredients || [""], loaded_list.recipes || []}
      else
        {shopping_list.ingredients || [""], []}
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:ingredients, ingredients)
     |> assign(:recipes, recipes)
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"shopping_list" => shopping_list_params}, socket) do
    shopping_list_params =
      Map.merge(shopping_list_params, %{
        "ingredients" => Enum.filter(socket.assigns.ingredients, &(String.trim(&1) != ""))
      })

    changeset =
      socket.assigns.shopping_list
      |> ShoppingLists.change_shopping_list(shopping_list_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"shopping_list" => shopping_list_params}, socket) do
    shopping_list_params =
      Map.merge(shopping_list_params, %{
        "ingredients" => Enum.filter(socket.assigns.ingredients, &(String.trim(&1) != ""))
      })

    save_shopping_list(socket, socket.assigns.action, shopping_list_params)
  end

  def handle_event("add_ingredient", _, socket) do
    ingredients = socket.assigns.ingredients ++ [""]
    {:noreply, assign(socket, :ingredients, ingredients)}
  end

  def handle_event("remove_ingredient", %{"index" => index}, socket) do
    index = String.to_integer(index)
    ingredients = List.delete_at(socket.assigns.ingredients, index)
    ingredients = if ingredients == [], do: [""], else: ingredients
    {:noreply, assign(socket, :ingredients, ingredients)}
  end

  def handle_event("update_ingredient", params, socket) do
    case params do
      %{"_target" => [target]} ->
        index =
          target
          |> String.replace("ingredient-", "")
          |> String.to_integer()

        value = params[target]

        ingredients = List.update_at(socket.assigns.ingredients, index, fn _ -> value end)
        {:noreply, assign(socket, :ingredients, ingredients)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("remove_recipe", %{"recipe-id" => recipe_id}, socket) do
    recipe_id = String.to_integer(recipe_id)
    recipe = Enum.find(socket.assigns.recipes, &(&1.id == recipe_id))

    case ShoppingLists.remove_recipe_from_shopping_list(socket.assigns.shopping_list, recipe) do
      {:ok, _updated_shopping_list} ->
        updated_shopping_list = ShoppingLists.get_shopping_list!(socket.assigns.shopping_list.id)

        {:noreply,
         socket
         |> assign(:recipes, updated_shopping_list.recipes)
         |> assign(:shopping_list, updated_shopping_list)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to remove recipe")}
    end
  end

  defp save_shopping_list(socket, :edit, shopping_list_params) do
    if ShoppingLists.can_edit_shopping_list?(
         socket.assigns.current_user,
         socket.assigns.shopping_list
       ) do
      case ShoppingLists.update_shopping_list(socket.assigns.shopping_list, shopping_list_params) do
        {:ok, shopping_list} ->
          notify_parent({:saved, shopping_list})

          {:noreply,
           socket
           |> put_flash(:info, "Shopping List updated successfully")
           |> push_navigate(to: socket.assigns.patch)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign_form(socket, changeset)}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "You can only edit shopping lists you created")
       |> push_navigate(to: ~p"/shopping-lists")}
    end
  end

  defp save_shopping_list(socket, :new, shoppping_list_params) do
    case ShoppingLists.create_shopping_list(shoppping_list_params, socket.assigns.current_user) do
      {:ok, shoppping_list} ->
        notify_parent({:created, shoppping_list})

        {:noreply,
         socket
         |> put_flash(:info, "Shopping List created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
