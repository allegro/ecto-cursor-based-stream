defmodule Cursornator.MixProject do
  use Mix.Project

  def project do
    [
      app: :cursornator,
      version: "1.3.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description:
        "Cursor-based query and stream of Ecto records that doesn't require database transaction.",
      package: [
        files: ["lib", ".formatter.exs", "mix.exs", "README*", "LICENSE*"],
        licenses: ["Apache-2.0"],
        links: %{
          "Source code" => "https://github.com/bluzky/ecto-cursor",
          "Documentation" => "https://hexdocs.pm/ecto_cursor"
        }
      ],
      docs: [
        main: "readme",
        source_url: "https://github.com/bluzky/ecto-cursor",
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
      {:ecto_sql, "~> 3.0", optional: true},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.32", only: :dev, runtime: false},
      {:postgrex, "~> 0.17", only: [:test]}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
