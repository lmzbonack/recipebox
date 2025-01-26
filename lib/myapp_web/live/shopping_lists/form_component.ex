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

        <:actions>
          <.button phx-disable-with="Saving...">Save Shopping List</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def update(%{shopping_list: shopping_list} = assigns, socket) do
    changeset = ShoppingLists.change_shopping_list(shopping_list)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"shopping_list" => shopping_list_params}, socket) do
    changeset =
      socket.assigns.shopping_list
      |> ShoppingLists.change_shopping_list(shopping_list_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"shopping_list" => shopping_list_params}, socket) do
    save_shopping_list(socket, socket.assigns.action, shopping_list_params)
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
