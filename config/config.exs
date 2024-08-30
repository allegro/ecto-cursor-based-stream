import Config

config :logger, level: :warning

config :cursornator, ecto_repos: [TestApp.Repo]

config :cursornator, TestApp.Repo,
  username: "postgres",
  password: "postgres",
  database: "test_cursor",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox
