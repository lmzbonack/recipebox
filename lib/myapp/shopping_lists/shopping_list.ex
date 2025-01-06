defmodule Myapp.ShoppingLists.ShoppingList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shopping_list" do
    field :name, :string
    field :ingredients, {:array, :string}
    belongs_to :created_by, Myapp.Accounts.User

    many_to_many :recipes, Myapp.Recipes.Recipe,
      join_through: Myapp.ShoppingListRecipe.ShoppingListRecipe,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(shopping_list, attrs) do
    shopping_list
    |> cast(attrs, [:name, :ingredients])
    |> validate_required([:name])
    |> cast_assoc(:recipes, with: &Myapp.Recipes.Recipe.changeset/2)
  end
end
