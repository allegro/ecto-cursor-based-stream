defmodule TestApp.Repo do
  use Ecto.Repo,
    otp_app: :test_app,
    adapter: Ecto.Adapters.Postgres

  use EctoCursorBasedStream
end
