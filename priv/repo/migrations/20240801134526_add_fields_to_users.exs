defmodule TestApp.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :country_of_birth, :string
      add :date_of_birth, :utc_datetime_usec
    end
  end
end
