import Config

config :logger, level: :warn

config :ecto_cursor_based_stream, ecto_repos: [TestApp.Repo]

config :ecto_cursor_based_stream, TestApp.Repo,
  username: "postgres",
  password: "postgres",
  database: "postgres",
  hostname: "localhost",
  port: 54323,
  pool: Ecto.Adapters.SQL.Sandbox
