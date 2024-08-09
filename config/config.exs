import Config

config :logger, level: :warning

config :ecto_cursor, ecto_repos: [TestApp.Repo]

config :ecto_cursor, TestApp.Repo,
  username: "postgres",
  password: "postgres",
  database: "test_cursor",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox
