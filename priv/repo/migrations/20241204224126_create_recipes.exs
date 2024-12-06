defmodule Myapp.Repo.Migrations.CreateRecipes do
  use Ecto.Migration

  def change do
    create table(:recipes) do
      add :name, :string, null: false
      add :author, :string, null: false
      add :external_link, :string
      add :prep_time_in_minutes, :integer
      add :cook_time_in_minutes, :integer
      add :ingredients, {:array, :string}, null: false
      add :instructions, {:array, :string}, null: false
      add :created_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:recipes, [:name])
  end
end
