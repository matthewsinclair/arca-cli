defmodule Arca.CLI.Commands.CliStatusCommand do
  @moduledoc """
  Arca CLI command to show the current status.
  """
  alias Arca.CLI.History
  use Arca.CLI.Command.BaseCommand

  config :"cli.status",
    name: "cli.status",
    about: "Show current CLI state."

  @doc """
  Show current CLI state (history)
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, settings, _optimus) do
    ["History entries: #{History.hlen()}", "Settings: #{inspect(settings)}"]
    |> Enum.join("\n")
  end
end