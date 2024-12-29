defmodule MyappWeb.RecipeLive.Index do
  use MyappWeb, :live_view

  alias Myapp.Recipes
  alias Myapp.Recipes.Recipe

  @impl true
  def mount(_params, _session, socket) do
    recipes = Recipes.list_recipes()
    {:ok, assign(socket, recipes: recipes)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Recipe")
    |> assign(:recipe, %Recipe{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Recipe")
    |> assign(:recipe, Recipes.get_recipe!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Recipes")
    |> assign(:recipe, nil)
  end

  @impl true
  def handle_info({MyappWeb.RecipeLive.FormComponent, {:saved, recipe}}, socket) do
    # Get the updated recipe from the database
    updated_recipe = Recipes.get_recipe!(recipe.id)

    # update the recipe we edited only
    updated_recipes =
      Enum.map(socket.assigns.recipes, fn r ->
        if r.id == recipe.id, do: updated_recipe, else: r
      end)

    {:noreply,
     socket
     |> assign(:recipes, updated_recipes)}
  end

  @impl true
  def handle_info({MyappWeb.RecipeLive.FormComponent, {:created, recipe}}, socket) do
    updated_recipe = Recipes.get_recipe!(recipe.id)

    {:noreply,
     socket
     |> assign(:recipes, [updated_recipe | socket.assigns.recipes])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {@page_title}
      <:actions>
        <.link
          patch={~p"/recipes/new"}
          class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
        >
          New Recipe
        </.link>
      </:actions>
    </.header>

    <.table
      id="recipes"
      rows={@recipes}
      row_click={fn recipe -> JS.navigate(~p"/recipes/#{recipe.id}") end}
    >
      <:col :let={recipe} label="Name">{recipe.name}</:col>
      <:col :let={recipe} label="Author">{recipe.author}</:col>
      <:col :let={recipe} label="Prep Time">{recipe.prep_time_in_minutes} min</:col>
      <:col :let={recipe} label="Cook Time">{recipe.cook_time_in_minutes} min</:col>
      <:action :let={recipe}>
        <.link patch={~p"/recipes/#{recipe.id}/edit"}>Edit</.link>
      </:action>
    </.table>

    <%= if @live_action in [:new, :edit] do %>
      <.modal :if={@recipe} id="recipe-modal" show on_cancel={JS.patch(~p"/recipes")}>
        <.live_component
          module={MyappWeb.RecipeLive.FormComponent}
          id={@recipe.id || :new}
          title={@page_title}
          action={@live_action}
          recipe={@recipe}
          patch={~p"/recipes"}
          current_user={@current_user}
        />
      </.modal>
    <% end %>
    """
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    recipe = Recipes.get_recipe!(id)
    {:ok, _} = Recipes.delete_recipe(recipe)

    {:noreply, assign(socket, recipes: Recipes.list_recipes())}
  end
end
