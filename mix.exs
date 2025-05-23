defmodule Arca.Cli.MixProject do
  use Mix.Project

  def project do
    [
      app: :arca_cli,
      version: "0.4.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Arca.Cli, path: "_build/escript/arca_cli", name: "arca_cli"],
      mix_tasks: [
        arca_cli: Mix.Tasks.Arca.Cli,
        comment: "📦 Arca CLI"
      ]
    ]
  end

  def application do
    [
      mod: {Arca.Cli, []},
      ansi_enabled: true
    ]
  end

  defp deps do
    [
      {:ok, "~> 2.3"},
      {:httpoison, "~> 2.1"},
      # {:optimus, "~> 0.5.0"},
      {:optimus, github: "matthewsinclair/arca-optimus", branch: "main", override: true},
      {:arca_config, github: "matthewsinclair/arca-config", branch: "main", override: true},
      {:castore, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:tesla, "~> 1.5"},
      {:certifi, "~> 2.9"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:owl, "~> 0.12"},
      {:ucwidth, "~> 0.2"},
      {:pathex, "~> 2.5"},
      {:table_rex, "~> 4.1"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_prompt, "~> 0.1.3"}
    ]
  end
end
