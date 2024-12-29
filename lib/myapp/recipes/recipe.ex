defmodule Myapp.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  schema "recipes" do
    field :name, :string
    field :author, :string
    field :external_link, :string
    field :prep_time_in_minutes, :integer
    field :cook_time_in_minutes, :integer
    field :ingredients, {:array, :string}
    field :instructions, {:array, :string}
    belongs_to :created_by, Myapp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [
      :name,
      :author,
      :external_link,
      :prep_time_in_minutes,
      :cook_time_in_minutes,
      :ingredients,
      :instructions,
      :created_by_id
    ])
    |> validate_required([:name, :author, :ingredients, :instructions])
    |> unique_constraint(:name)
    |> validate_number(:prep_time_in_minutes, greater_than: 0)
    |> validate_number(:cook_time_in_minutes, greater_than: 0)
  end
end
