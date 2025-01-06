defmodule MyappWeb.RecipeLive.Show do
  use MyappWeb, :live_view

  alias Myapp.Recipes

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    recipe = Recipes.get_recipe!(id)
    {:ok, assign(socket, recipe: recipe, page_title: recipe.name)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit #{socket.assigns.recipe.name}")
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  @impl true
  def handle_info({MyappWeb.RecipeLive.FormComponent, {:saved, recipe}}, socket) do
    {:noreply,
     socket
     |> assign(recipe: Recipes.get_recipe!(recipe.id))
     |> assign(page_title: recipe.name)}
  end

  @impl true
  def handle_event("delete_recipe", _, socket) do
    Recipes.delete_recipe(socket.assigns.recipe)

    {:noreply,
     socket
     |> put_flash(:info, "Recipe deleted successfully")
     |> push_navigate(to: ~p"/recipes")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header class="mb-2">
      <.link href={@recipe.external_link} target="_blank" class="text-blue-600 hover:underline">
        {@recipe.name}
      </.link>
      <:subtitle>By: {@recipe.author}</:subtitle>
      <:actions>
        <%= if Recipes.can_edit_recipe?(@current_user, @recipe) do %>
          <.link patch={~p"/recipes/#{@recipe.id}/details/edit"}>
            <.button>Edit</.button>
          </.link>
        <% end %>
        <%= if Recipes.can_edit_recipe?(@current_user, @recipe) do %>
          <.button
            id="delete-recipe"
            phx-click="delete_recipe"
            data-confirm="Are you sure you want to delete this recipe?"
          >
            Delete
          </.button>
        <% end %>
      </:actions>
    </.header>

    <.list>
      <:item title="Preparation Time">{@recipe.prep_time_in_minutes} minutes</:item>
      <:item title="Cooking Time">{@recipe.cook_time_in_minutes} minutes</:item>
      <:item title="Created By">{@recipe.created_by.email}</:item>
    </.list>

    <div class="mt-10">
      <h2 class="text-lg font-semibold leading-8 text-zinc-800">Ingredients</h2>
      <ul class="mt-4 list-disc list-inside space-y-2">
        <%= for ingredient <- @recipe.ingredients do %>
          <li class="text-zinc-600">{ingredient}</li>
        <% end %>
      </ul>
    </div>

    <div class="mt-10">
      <h2 class="text-lg font-semibold leading-8 text-zinc-800">Instructions</h2>
      <ol class="mt-4 list-decimal list-inside space-y-4">
        <%= for instruction <- @recipe.instructions do %>
          <li class="text-zinc-600">{instruction}</li>
        <% end %>
      </ol>
    </div>

    <.back navigate={~p"/recipes"}>Back to recipes</.back>

    <%= if @live_action == :edit do %>
      <.modal :if={@recipe} id="recipe-modal" show on_cancel={JS.patch(~p"/recipes/#{@recipe.id}")}>
        <.live_component
          module={MyappWeb.RecipeLive.FormComponent}
          id={@recipe.id}
          title={@page_title}
          action={@live_action}
          recipe={@recipe}
          patch={~p"/recipes/#{@recipe.id}"}
          current_user={@current_user}
        />
      </.modal>
    <% end %>
    """
  end
end
