defmodule Myapp.Repo.Migrations.CreateShoppingListsRecipes do
  use Ecto.Migration

  def change do
    create table(:shopping_lists_recipes) do
      add :shopping_list_id, references(:shopping_list, on_delete: :delete_all)
      add :recipe_id, references(:recipes, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:shopping_lists_recipes, [:shopping_list_id])
    create index(:shopping_lists_recipes, [:recipe_id])
    # Prevent duplicate recipes in the same shopping list
    create unique_index(:shopping_lists_recipes, [:shopping_list_id, :recipe_id])
  end
end
