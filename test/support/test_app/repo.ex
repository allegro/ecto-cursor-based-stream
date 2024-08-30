defmodule TestApp.Repo do
  use Ecto.Repo,
    otp_app: :cursornator,
    adapter: Ecto.Adapters.Postgres

  use Cursornator
end
