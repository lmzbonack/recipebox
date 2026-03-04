defmodule MyappWeb.RecipeLive.Show do
  use MyappWeb, :live_view

  alias Myapp.Recipes
  alias Myapp.ShoppingLists

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    recipe = Recipes.get_recipe!(id)
    {:ok, assign(socket, recipe: recipe, page_title: recipe.name, show_select_modal: false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit #{socket.assigns.recipe.name}")
  end

  defp apply_action(socket, :show, params) do
    socket =
      if params["action"] == "add_to_shopping_list" do
        shopping_lists = ShoppingLists.list_user_shopping_lists(socket.assigns.current_user)

        socket
        |> assign(:shopping_lists, shopping_lists)
        |> assign(:show_select_modal, true)
      else
        socket
        |> assign(:show_select_modal, false)
      end

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
  def handle_event("select_shopping_list", %{"id" => shopping_list_id}, socket) do
    shopping_list = ShoppingLists.get_shopping_list!(shopping_list_id)
    recipe = socket.assigns.recipe

    case ShoppingLists.add_recipe_to_shopping_list(shopping_list, recipe) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recipe added to #{shopping_list.name} successfully")
         |> push_patch(to: ~p"/recipes/#{recipe.id}")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to add recipe to shopping list")
         |> push_patch(to: ~p"/recipes/#{recipe.id}")}
    end
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
            <.button class="bg-yellow-500 text-black">Edit</.button>
          </.link>
        <% end %>
        <.button
          id="add-to-shopping-list"
          class="bg-green-500 text-black"
          phx-click={JS.patch(~p"/recipes/#{@recipe.id}?action=add_to_shopping_list")}
        >
          Add to Shopping List
        </.button>
        <%= if Recipes.can_edit_recipe?(@current_user, @recipe) do %>
          <.button
            id="delete-recipe"
            class="bg-red-500 text-white"
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

    <%= if @show_select_modal do %>
      <.modal id="select-shopping-list-modal" show on_cancel={JS.patch(~p"/recipes/#{@recipe.id}")}>
        <div class="px-6">
          <h2 class="text-lg font-semibold leading-8 text-zinc-800 mb-4">
            Select a Shopping List
          </h2>

          <%= if Enum.empty?(@shopping_lists) do %>
            <p class="text-zinc-600 mb-4">You don't have any shopping lists yet.</p>
            <.link navigate={~p"/shopping-lists/new"} class="text-blue-600 hover:underline">
              Create a new shopping list
            </.link>
          <% else %>
            <div class="space-y-2">
              <%= for shopping_list <- @shopping_lists do %>
                <.button
                  phx-click="select_shopping_list"
                  phx-value-id={shopping_list.id}
                  class="text-left justify-start"
                >
                  {shopping_list.name}
                </.button>
              <% end %>
            </div>
          <% end %>
        </div>
      </.modal>
    <% end %>
    """
  end
end
