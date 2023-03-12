import Config

config :logger, level: :warn

config :ecto_cursor_based_stream, ecto_repos: [TestApp.Repo]

config :ecto_cursor_based_stream, TestApp.Repo,
  username: "postgres",
  password: "postgres",
  database: "postgres",
  hostname: "localhost",
  port: System.get_env("DB_PORT", "5432"),
  pool: Ecto.Adapters.SQL.Sandbox

config :mix_test_watch, clear: true

level = if System.get_env("DEBUG"), do: :debug, else: :info

config :logger, :console,
  level: level,
  format: "$date $time [$level] $metadata$message\n"
