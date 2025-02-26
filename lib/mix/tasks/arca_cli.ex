defmodule Mix.Tasks.Arca.Cli do
  @moduledoc "Custom mix tasks for Arca CLI: mix arca.cli"
  use Mix.Task
  alias Arca.Cli, as: Cli

  @impl Mix.Task
  @requirements ["app.config", "app.start"]
  @shortdoc "Runs the Arca CLI"
  @doc "Invokes the Arca CLI and passes it the supplied command line params."
  def run(args) do
    Cli.main(args)
  end
end
