import Config

config :logger, level: :warn

config :test_app, ecto_repos: [TestApp.Repo]

config :test_app, TestApp.Repo,
  username: "postgres",
  password: "postgres",
  database: "postgres",
  hostname: "localhost",
  port: 54323,
  pool: Ecto.Adapters.SQL.Sandbox
