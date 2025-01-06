defmodule Myapp.ShoppingLists do
  @moduledoc """
  The ShoppingLists context.
  """

  import Ecto.Query, warn: false
  alias Myapp.Repo
  alias Myapp.ShoppingLists.ShoppingList
  alias Myapp.Accounts.User
  alias Myapp.Recipes.Recipe

  @doc """
  Gets a single shopping list.
  Returns nil if the ShoppingList does not exist.
  """
  def get_shopping_list(id) do
    ShoppingList
    |> Repo.get(id)
    |> Repo.preload([:created_by, :recipes])
  end

  @doc """
  Gets a single shopping list.
  Raises `Ecto.NoResultsError` if the ShoppingList does not exist.
  """
  def get_shopping_list!(id) do
    ShoppingList
    |> Repo.get!(id)
    |> Repo.preload([:created_by, :recipes])
  end

  @doc """
  Creates a shopping list.
  """
  def create_shopping_list(attrs \\ %{}, user) do
    %ShoppingList{}
    |> ShoppingList.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:created_by, user)
    |> Repo.insert()
  end

  @doc """
  Updates a shopping list.
  """
  def update_shopping_list(%ShoppingList{} = shopping_list, attrs) do
    shopping_list
    |> ShoppingList.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a shopping list.
  """
  def delete_shopping_list(%ShoppingList{} = shopping_list) do
    Repo.delete(shopping_list)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking shopping list changes.
  """
  def change_shopping_list(%ShoppingList{} = shopping_list, attrs \\ %{}) do
    ShoppingList.changeset(shopping_list, attrs)
  end

  @doc """
  Returns the list of shopping lists for a specific user.
  """
  def list_user_shopping_lists(%User{} = user) do
    ShoppingList
    |> where([s], s.created_by_id == ^user.id)
    |> Repo.all()
    |> Repo.preload([:created_by, :recipes])
  end

  @doc """
  Adds a recipe to a shopping list.
  """
  def add_recipe_to_shopping_list(%ShoppingList{} = shopping_list, %Recipe{} = recipe) do
    shopping_list = Repo.preload(shopping_list, :recipes)
    recipes = [recipe | shopping_list.recipes || []]

    shopping_list
    |> ShoppingList.changeset(%{})
    |> Ecto.Changeset.put_assoc(:recipes, recipes)
    |> Repo.update()
  end

  @doc """
  Removes a recipe from a shopping list.
  """
  def remove_recipe_from_shopping_list(%ShoppingList{} = shopping_list, %Recipe{} = recipe) do
    shopping_list
    |> Repo.preload(:recipes)
    |> ShoppingList.changeset(%{})
    |> Ecto.Changeset.put_assoc(
      :recipes,
      Enum.reject(shopping_list.recipes, &(&1.id == recipe.id))
    )
    |> Repo.update()
  end

  def can_edit_shopping_list?(%User{id: user_id}, %ShoppingList{created_by_id: created_by_id}) do
    user_id == created_by_id
  end
end
