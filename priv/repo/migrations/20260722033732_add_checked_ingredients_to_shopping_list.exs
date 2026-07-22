defmodule Myapp.Repo.Migrations.AddCheckedIngredientsToShoppingList do
  use Ecto.Migration

  def change do
    alter table(:shopping_list) do
      add :checked_ingredients, {:array, :string}, default: []
    end
  end
end
