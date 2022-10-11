defmodule TestApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def up do
    create table(:users) do
      add :email, :string, null: false
    end
  end

  def down do
    drop table(:users)
  end
end
