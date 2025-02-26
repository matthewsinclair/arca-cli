defmodule Arca.CLI.Commands.FlushCommand do
  @moduledoc """
  Flush the history of previous commands.
  """
  use Arca.CLI.Command.BaseCommand

  config :flush,
    name: "flush",
    about: "Flush the command history."

  @doc """
  Flush the history of previous commands.
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    Arca.CLI.History.flush_history()
    "ok"
  end
end
