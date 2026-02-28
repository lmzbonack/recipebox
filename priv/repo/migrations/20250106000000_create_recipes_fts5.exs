defmodule Myapp.Repo.Migrations.CreateRecipesFts5 do
  use Ecto.Migration

  def change do
    execute """
    CREATE VIRTUAL TABLE IF NOT EXISTS recipes_fts USING fts5(
      name,
      author,
      ingredients,
      content='recipes',
      content_rowid='rowid'
    );
    """

    execute """
    CREATE TRIGGER IF NOT EXISTS recipes_ai AFTER INSERT ON recipes BEGIN
      INSERT INTO recipes_fts(rowid, name, author, ingredients)
      VALUES (NEW.rowid, NEW.name, NEW.author, NEW.ingredients);
    END;
    """

    execute """
    CREATE TRIGGER IF NOT EXISTS recipes_ad AFTER DELETE ON recipes BEGIN
      INSERT INTO recipes_fts(recipes_fts, rowid, name, author, ingredients)
      VALUES ('delete', OLD.rowid, OLD.name, OLD.author, OLD.ingredients);
    END;
    """

    execute """
    CREATE TRIGGER IF NOT EXISTS recipes_au AFTER UPDATE ON recipes BEGIN
      INSERT INTO recipes_fts(recipes_fts, rowid, name, author, ingredients)
      VALUES ('delete', OLD.rowid, OLD.name, OLD.author, OLD.ingredients);
      INSERT INTO recipes_fts(rowid, name, author, ingredients)
      VALUES (NEW.rowid, NEW.name, NEW.author, NEW.ingredients);
    END;
    """

    execute "INSERT INTO recipes_fts(recipes_fts) VALUES ('rebuild');"
  end
end
