defmodule MyappWeb.RecipeLive.FormComponent do
  use MyappWeb, :live_component

  alias Myapp.Recipes

  @impl true
  def render(assigns) do
    ~H"""
    <div id="recipe-form-container">
      <.header>
        {@title}
      </.header>

      <%= if @action == :new do %>
        <div class="mb-6">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Import from URL
          </label>
          <form phx-submit="scrape_recipe" phx-target={@myself} class="mt-2">
            <div class="flex gap-2">
              <input
                type="url"
                id="recipe-external-link"
                name="url"
                value={@scrape_url || @recipe.external_link || ""}
                class="flex-1 block w-full rounded-md border-0 py-1.5 text-zinc-900 shadow-sm ring-1 ring-inset ring-zinc-300 placeholder:text-zinc-400 focus:ring-2 focus:ring-inset focus:ring-zinc-600 sm:text-sm sm:leading-6"
                placeholder="https://example.com/recipe"
              />
              <button
                type="submit"
                class="px-3 py-2 text-sm font-semibold text-white bg-zinc-900 rounded-md hover:bg-zinc-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-zinc-600 disabled:opacity-50 disabled:cursor-not-allowed"
                disabled={@scrape_loading}
              >
                <%= if @scrape_loading do %>
                  <span class="flex items-center gap-2">
                    <svg
                      class="animate-spin h-4 w-4"
                      xmlns="http://www.w3.org/2000/svg"
                      fill="none"
                      viewBox="0 0 24 24"
                    >
                      <circle
                        class="opacity-25"
                        cx="12"
                        cy="12"
                        r="10"
                        stroke="currentColor"
                        stroke-width="4"
                      >
                      </circle>
                      <path
                        class="opacity-75"
                        fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                      >
                      </path>
                    </svg>
                    Scraping...
                  </span>
                <% else %>
                  Scrape
                <% end %>
              </button>
            </div>
          </form>
          <%= if @scrape_status == :success do %>
            <p class="mt-2 text-sm text-emerald-700">Scrape successful.</p>
          <% end %>
          <%= if @scrape_status == :failed do %>
            <p class="mt-2 text-sm text-rose-700">Scrape failed.</p>
          <% end %>
        </div>
      <% end %>

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
        <.input field={@form[:external_link]} type="url" label="External Link" />

        <div class="space-y-2">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Ingredients
          </label>

          <div :for={{ingredient, i} <- Enum.with_index(@ingredients)} class="space-y-2">
            <.input
              field={@form[:ingredient]}
              id={"recipe_ingredient-#{i}"}
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
              id={"recipe_instruction-#{i}"}
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

        <:actions>
          <.button phx-disable-with="Saving...">Save Recipe</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{recipe: recipe} = assigns, socket) do
    changeset = Recipes.change_recipe(recipe)

    socket =
      socket
      |> assign(assigns)
      |> assign(:ingredients, recipe.ingredients || [""])
      |> assign(:instructions, recipe.instructions || [""])
      |> assign(:scrape_url, recipe.external_link)
      |> assign(:scrape_loading, false)
      |> assign(:scrape_status, nil)
      |> assign_form(changeset)

    socket =
      if Map.has_key?(assigns, :scraped_data) do
        apply_scraped_data(socket, assigns.scraped_data)
      else
        socket
      end

    {:ok, socket}
  end

  def update(%{scraped_data: _} = assigns, socket) do
    socket = assign(socket, :scrape_loading, Map.get(assigns, :scrape_loading, false))

    if Map.has_key?(assigns, :scraped_data) do
      {:ok, apply_scraped_data(socket, assigns.scraped_data)}
    else
      {:ok, socket}
    end
  end

  def update(%{scrape_loading: scrape_loading} = _assigns, socket) do
    {:ok, assign(socket, :scrape_loading, scrape_loading)}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  defp apply_scraped_data(socket, data) do
    name = Map.get(data, "name") || Map.get(data, :name)
    author = Map.get(data, "author") || Map.get(data, :author)
    prep_time = Map.get(data, "prep_time_in_minutes") || Map.get(data, :prep_time_in_minutes)
    cook_time = Map.get(data, "cook_time_in_minutes") || Map.get(data, :cook_time_in_minutes)
    ingredients = Map.get(data, "ingredients") || Map.get(data, :ingredients) || []
    instructions = Map.get(data, "instructions") || Map.get(data, :instructions) || []
    external_link = Map.get(data, "external_link") || socket.assigns.recipe.external_link

    updated_recipe = %{
      socket.assigns.recipe
      | name: name,
        author: author,
        prep_time_in_minutes: prep_time,
        cook_time_in_minutes: cook_time,
        ingredients: ingredients,
        instructions: instructions,
        external_link: external_link
    }

    changeset = Recipes.change_recipe(updated_recipe)

    socket
    |> assign(:recipe, updated_recipe)
    |> assign(:scrape_url, socket.assigns.scrape_url)
    |> assign(:ingredients, ingredients)
    |> assign(:instructions, instructions)
    |> assign(:scrape_loading, false)
    |> assign_form(changeset)
  end

  defp scrape_url(url) do
    url =
      if String.starts_with?(url, "http://") or String.starts_with?(url, "https://"),
        do: url,
        else: "https://" <> url

    case Myapp.Scraping.scrape_recipe_url(url) do
      {:ok, recipe_data} ->
        %{success: true, data: recipe_data}

      {:error, :missing_credentials} ->
        %{success: false, error: "Cloudflare API credentials not configured"}

      {:error, %{transport_error: reason}} ->
        %{success: false, error: "Request timed out or failed: #{inspect(reason)}"}

      {:error, reason} when is_atom(reason) ->
        %{success: false, error: inspect(reason)}

      {:error, %{status: status, body: body}} ->
        %{success: false, error: "API error", status: status, details: body}

      {:error, %{api_errors: errors}} ->
        %{success: false, error: "API error", errors: errors}
    end
  end

  @impl true
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

  def handle_event("scrape_recipe", %{"url" => url}, socket) do
    if url == "" or is_nil(url) do
      {:noreply, assign(socket, :scrape_status, :failed)}
    else
      socket =
        socket
        |> assign(scrape_url: url, scrape_loading: true, scrape_status: nil)
        |> start_async(:scrape_recipe, fn -> scrape_url(url) end)

      {:noreply, socket}
    end
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

  @impl true
  def handle_async(:scrape_recipe, {:ok, result}, socket) do
    url = socket.assigns.scrape_url
    socket =
      if result.success do
        scraped_data = Map.merge(result.data, %{scrape_url: url})
        socket
        |> apply_scraped_data(scraped_data)
        |> assign(:scrape_status, :success)
      else
        assign(socket, :scrape_status, :failed)
      end

    {:noreply, assign(socket, :scrape_loading, false)}
  end

  defp save_recipe(socket, :edit, recipe_params) do
    if Recipes.can_edit_recipe?(socket.assigns.current_user, socket.assigns.recipe) do
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
    else
      {:noreply,
       socket
       |> put_flash(:error, "You can only edit recipes you created")
       |> push_navigate(to: ~p"/recipes")}
    end
  end

  defp save_recipe(socket, :new, recipe_params) do
    case Recipes.create_recipe(recipe_params, socket.assigns.current_user) do
      {:ok, _recipe} ->
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
