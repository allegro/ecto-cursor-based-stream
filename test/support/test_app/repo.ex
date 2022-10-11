defmodule TestApp.Repo do
  use Ecto.Repo,
    otp_app: :ecto_cursor_based_stream,
    adapter: Ecto.Adapters.Postgres

  use EctoCursorBasedStream
end
