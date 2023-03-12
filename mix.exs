defmodule EctoCursorBasedStream.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_cursor_based_stream,
      version: "1.0.1",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "Cursor-based streaming of Ecto records that doesn't require database transaction.",
      package: [
        files: ["lib", ".formatter.exs", "mix.exs", "README*", "LICENSE*"],
        licenses: ["Apache-2.0"],
        links: %{
          "Source code" => "https://github.com/allegro/ecto-cursor-based-stream",
          "Documentation" => "https://hexdocs.pm/ecto_cursor_based_stream"
        }
      ],
      docs: [
        main: "readme",
        source_url: "https://github.com/allegro/ecto-cursor-based-stream",
        extras: ["README.md"]
      ],
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:mix_test_watch, "~> 1.1.0", only: [:dev, :test]},
      {:postgrex, "~> 0.16", only: [:test]}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
