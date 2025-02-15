defmodule Arca.CLI.Commands.StatusCommand do
  @moduledoc """
  Arca CLI command to show current status of everything.
  """
  use Arca.CLI.Command.BaseCommand

  config :status,
    name: "status",
    about: "Show current CLI state."

  @doc """
  Show current status of everything.
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    # TODO: Redo to print the status in a more user-friendly way
    inspect(Arca.CLI.History.state())
  end
end
