defmodule Arca.Cli.Commands.RedoCommand do
  @moduledoc """
  Arca CLI command to redo a previous command from the command history.
  """
  use Arca.Cli.Command.BaseCommand

  config :redo,
    name: "redo",
    about: "Redo a previous command from the history.",
    multiple: false,
    allow_unknown_args: false,
    args: [
      params: [
        value_name: "CMD",
        help: "ID of previous command",
        required: true
      ]
    ]

  @doc """
  Arca CLI command to redo a previous command from the command history.
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(args, settings, optimus) do
    history = Arca.Cli.History.history()
    index = String.to_integer(args.args.params)

    if index < 0 or index >= length(history) do
      IO.puts("error: invalid command index: #{index}")
    else
      command = Enum.at(history, index)
      Arca.Cli.Repl.eval_for_redo(command, settings, optimus)
    end
  end
end
