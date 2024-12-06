defmodule MyappWeb.RecipeLive.FormComponent do
  use MyappWeb, :live_component

  alias Myapp.Recipes

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to create or edit a recipe.</:subtitle>
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
        <.input
          field={@form[:ingredients]}
          type="textarea"
          label="Ingredients"
        />
        <.input
          field={@form[:instructions]}
          type="textarea"
          label="Instructions"
        />
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
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"recipe" => recipe_params}, socket) do
    # Convert textarea input to list for ingredients and instructions
    recipe_params = parse_lists(recipe_params)

    changeset =
      socket.assigns.recipe
      |> Recipes.change_recipe(recipe_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"recipe" => recipe_params}, socket) do
    # Convert textarea input to list for ingredients and instructions
    recipe_params = parse_lists(recipe_params)

    save_recipe(socket, socket.assigns.action, recipe_params)
  end

  defp save_recipe(socket, :edit, recipe_params) do
    case Recipes.update_recipe(socket.assigns.recipe, recipe_params) do
      {:ok, recipe} ->
        notify_parent({:saved, recipe})
        {:noreply,
         socket
         |> put_flash(:info, "Recipe updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_recipe(socket, :new, recipe_params) do
    case Recipes.create_recipe(recipe_params, socket.assigns.current_user) do
      {:ok, recipe} ->
        notify_parent({:saved, recipe})
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

  defp parse_lists(%{"ingredients" => ingredients, "instructions" => instructions} = params) do
    params
    |> Map.put("ingredients", String.split(ingredients, "\n", trim: true))
    |> Map.put("instructions", String.split(instructions, "\n", trim: true))
  end
end
