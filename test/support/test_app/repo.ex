defmodule TestApp.Repo do
  use Ecto.Repo,
    otp_app: :ecto_cursor,
    adapter: Ecto.Adapters.Postgres

  use EctoCursor
end
