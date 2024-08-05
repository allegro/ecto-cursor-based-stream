defmodule TestApp.Repo.Migrations.CreateMultiCursorTable do
  use Ecto.Migration

  def change do
    create table(:multi_cursor, primary_key: false) do
      add :id_1, :integer, primary_key: true
      add :id_2, :integer, primary_key: true
      add :id_3, :integer, primary_key: true
    end
  end
end
