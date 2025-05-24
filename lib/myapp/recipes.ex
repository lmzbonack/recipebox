defmodule Myapp.Recipes do
  @moduledoc """
  The Recipes context.
  """

  import Ecto.Query, warn: false
  alias Myapp.Repo
  alias Myapp.Recipes.Recipe
  alias Myapp.Accounts.User

  @doc """
  Returns the list of recipes.
  """

  def list_recipes(page \\ 1, per_page \\ 25) do
    Recipe
    |> order_by([r], desc: r.inserted_at)
    |> limit(^per_page)
    |> offset(^((page - 1) * per_page))
    |> Repo.all()
    |> Repo.preload(:created_by)
  end

  @doc """
  Gets a single recipe.
  Returns nil if the Recipe does not exist.
  """
  def get_recipe(id) do
    Recipe
    |> Repo.get(id)
    |> Repo.preload(:created_by)
  end

  @spec get_recipe!(any()) :: nil | [%{optional(atom()) => any()}] | %{optional(atom()) => any()}
  @doc """
  Gets a single recipe.
  Raises `Ecto.NoResultsError` if the Recipe does not exist.
  """
  def get_recipe!(id) do
    Recipe
    |> Repo.get!(id)
    |> Repo.preload(:created_by)
  end

  @doc """
  Creates a recipe.
  """
  def create_recipe(attrs \\ %{}, user) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:created_by, user)
    |> Repo.insert()
  end

  @doc """
  Updates a recipe.
  """
  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a recipe.
  """
  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking recipe changes.
  """
  def change_recipe(%Recipe{} = recipe, attrs \\ %{}) do
    Recipe.changeset(recipe, attrs)
  end

  @doc """
  Returns the list of recipes for a specific user.
  """
  def list_user_recipes(%User{} = user) do
    Recipe
    |> where([r], r.created_by_id == ^user.id)
    |> Repo.all()
    |> Repo.preload(:created_by)
  end

  def can_edit_recipe?(%Myapp.Accounts.User{id: user_id}, %Recipe{created_by_id: created_by_id}) do
    user_id == created_by_id
  end
end
