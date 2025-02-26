defmodule Arca.CLI.Commands.ReplCommand do
  @moduledoc """
  Arca CLI command to start the REPL.
  """
  alias Arca.CLI.Repl
  use Arca.CLI.Command.BaseCommand

  config :repl,
    name: "repl",
    about: "Start the Arca REPL.",
    multiple: true,
    allow_unknown_args: true,
    hidden: true,
    args: [
      params: [
        value_name: "PARAMS",
        help: "additional paramaters",
        required: false
      ]
    ]

  @doc """
  Start the REPL.
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(args, settings, optimus) do
    Repl.start(args, settings, optimus)
    ""
  end
end
