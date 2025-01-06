defmodule MyappWeb.RecipeLive.FormComponent do
  use MyappWeb, :live_component

  alias Myapp.Recipes

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Editing {@recipe.name}</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="recipe-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:author]} type="text" label="Author" />
        <.input field={@form[:prep_time_in_minutes]} type="number" label="Prep Time (minutes)" />
        <.input field={@form[:cook_time_in_minutes]} type="number" label="Cook Time (minutes)" />

        <div class="space-y-2">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Ingredients
          </label>

          <div :for={{ingredient, i} <- Enum.with_index(@ingredients)} class="space-y-2">
            <.input
              field={@form[:ingredient]}
              name={"ingredient-#{i}"}
              type="text"
              value={ingredient}
              phx-target={@myself}
              phx-change="update_ingredient"
              phx-value-index={i}
              rows="2"
            />
            <div class="flex justify-end">
              <button
                type="button"
                phx-click="remove_ingredient"
                phx-value-index={i}
                phx-target={@myself}
                class="px-2 py-1 text-sm text-red-600 hover:text-red-700"
              >
                Remove
              </button>
            </div>
          </div>

          <button
            type="button"
            phx-click="add_ingredient"
            phx-target={@myself}
            class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
          >
            Add Ingredient
          </button>
        </div>

        <div class="space-y-2">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Instructions
          </label>

          <div :for={{instruction, i} <- Enum.with_index(@instructions)} class="space-y-2">
            <.input
              field={@form[:instruction]}
              name={"instruction-#{i}"}
              type="textarea"
              value={instruction}
              phx-target={@myself}
              phx-change="update_instruction"
              phx-value-index={i}
            />
            <div class="flex justify-end">
              <button
                type="button"
                phx-click="remove_instruction"
                phx-value-index={i}
                phx-target={@myself}
                class="px-2 py-1 text-sm text-red-600 hover:text-red-700"
              >
                Remove
              </button>
            </div>
          </div>

          <button
            type="button"
            phx-click="add_instruction"
            phx-target={@myself}
            class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
          >
            Add Instruction
          </button>
        </div>

        <.input field={@form[:external_link]} type="text" label="External Link (optional)" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Recipe</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def update(%{recipe: recipe} = assigns, socket) do
    changeset = Recipes.change_recipe(recipe)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:ingredients, recipe.ingredients || [""])
     |> assign(:instructions, recipe.instructions || [""])
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    recipe_params =
      Map.merge(recipe_params, %{
        "ingredients" => Enum.filter(socket.assigns.ingredients, &(String.trim(&1) != "")),
        "instructions" => Enum.filter(socket.assigns.instructions, &(String.trim(&1) != ""))
      })

    changeset =
      socket.assigns.recipe
      |> Recipes.change_recipe(recipe_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    recipe_params =
      Map.merge(recipe_params, %{
        "ingredients" => Enum.filter(socket.assigns.ingredients, &(String.trim(&1) != "")),
        "instructions" => Enum.filter(socket.assigns.instructions, &(String.trim(&1) != ""))
      })

    save_recipe(socket, socket.assigns.action, recipe_params)
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

  def handle_event("add_instruction", _, socket) do
    instructions = socket.assigns.instructions ++ [""]
    {:noreply, assign(socket, :instructions, instructions)}
  end

  def handle_event("remove_instruction", %{"index" => index}, socket) do
    index = String.to_integer(index)
    instructions = List.delete_at(socket.assigns.instructions, index)
    instructions = if instructions == [], do: [""], else: instructions
    {:noreply, assign(socket, :instructions, instructions)}
  end

  def handle_event("update_instruction", params, socket) do
    case params do
      %{"_target" => [target]} ->
        index =
          target
          |> String.replace("instruction-", "")
          |> String.to_integer()

        value = params[target]

        instructions = List.update_at(socket.assigns.instructions, index, fn _ -> value end)
        {:noreply, assign(socket, :instructions, instructions)}

      _ ->
        {:noreply, socket}
    end
  end

  defp save_recipe(socket, :edit, recipe_params) do
    case Recipes.update_recipe(socket.assigns.recipe, recipe_params) do
      {:ok, recipe} ->
        notify_parent({:saved, recipe})

        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_recipe(socket, :new, recipe_params) do
    case Recipes.create_recipe(recipe_params, socket.assigns.current_user) do
      {:ok, recipe} ->
        notify_parent({:created, recipe})

        {:noreply,
         socket
         |> put_flash(:info, "Recipe created successfully")
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
