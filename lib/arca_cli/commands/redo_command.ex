defmodule Arca.CLI.Commands.RedoCommand do
  @moduledoc """
  Arca CLI command to redo a previous command from the command history.
  """
  use Arca.CLI.Command.BaseCommand

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
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(args, settings, optimus) do
    history = Arca.CLI.History.history()
    index = String.to_integer(args.args.params)

    if index < 0 or index >= length(history) do
      IO.puts("error: invalid command index: #{index}")
    else
      command = Enum.at(history, index)
      Arca.CLI.Repl.eval_for_redo(command, settings, optimus)
    end
  end
end
