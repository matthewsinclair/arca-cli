defmodule Arca.Cli.Commands.CliRedoCommand do
  @moduledoc """
  Redo a previous command from the command history.
  """
  alias Arca.Cli.{Repl, History}
  use Arca.Cli.Command.BaseCommand

  config :"cli.redo",
    name: "cli.redo",
    about: "Redo a previous command from the history.",
    args: [
      idx: [
        value_name: "IDX",
        help: "Command index",
        required: true,
        parser: :integer
      ]
    ]

  @doc """
  Redo a specific command by index from History
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(args, settings, optimus) do
    history = History.history()
    idx = args.args.idx

    if idx >= 0 && idx < length(history) do
      history
      |> Enum.at(idx)
      |> Repl.eval_for_redo(settings, optimus)
    else
      "error: invalid command index: #{idx}"
    end
  end
end
