defmodule TestApp.User do
  use Ecto.Schema

  schema "users" do
    field(:email, :string)
    field(:country_of_birth, :string)
    field(:date_of_birth, :utc_datetime_usec)
  end
end
