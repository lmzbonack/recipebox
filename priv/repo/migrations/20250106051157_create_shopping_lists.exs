defmodule Myapp.Repo.Migrations.CreateShoppingLists do
  use Ecto.Migration

  def change do
    create table(:shopping_list) do
      add :name, :string, null: false
      add :ingredients, {:array, :string}, default: []
      add :created_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:shopping_list, [:created_by_id])
  end
end
