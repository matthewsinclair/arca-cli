defmodule Arca.CLI.MixProject do
  use Mix.Project

  def project do
    [
      app: :arca_cli,
      version: "0.3.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Arca.CLI, path: "_build/escript/arca_cli", name: "arca_cli"],
      mix_tasks: [
        arca_cli: Mix.Tasks.Arca.CLI,
        comment: "📦 Arca CLI"
      ]
    ]
  end

  def application do
    [
      mod: {Arca.CLI, []},
      ansi_enabled: true
    ]
  end

  defp deps do
    [
      {:ok, "~> 2.3"},
      {:httpoison, "~> 2.1"},
      {:optimus, "~> 0.2"},
      {:castore, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:tesla, "~> 1.5"},
      {:certifi, "~> 2.9"},
      {:ex_doc, "~> 0.29"},
      {:owl, "~> 0.12"},
      {:ucwidth, "~> 0.2"},
      {:pathex, "~> 2.5"},
      {:table_rex, "~> 4.0"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_prompt, "~> 0.1.3"},
      {:arca_config, path: "../config"}
    ]
  end
end
