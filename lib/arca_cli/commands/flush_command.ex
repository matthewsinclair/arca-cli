defmodule Arca.Cli.Commands.FlushCommand do
  @moduledoc """
  Flush the history of previous commands.
  """
  use Arca.Cli.Command.BaseCommand

  config :flush,
    name: "flush",
    about: "Flush the command history."

  @doc """
  Flush the history of previous commands.
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    Arca.Cli.History.flush_history()
    "ok"
  end
end
