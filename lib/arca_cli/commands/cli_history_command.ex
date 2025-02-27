defmodule Arca.Cli.Commands.CliHistoryCommand do
  @moduledoc """
  Arca CLI command to list command history.
  """
  alias Arca.Cli.History
  use Arca.Cli.Command.BaseCommand

  config :"cli.history",
    name: "cli.history",
    about: "Show a history of recent commands."

  @doc """
  List the history of commands
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    case History.history() do
      [] -> "No command history."
      h -> format_history(h)
    end
  end

  defp format_history(history) do
    history
    |> Enum.map(fn {idx, cmd} -> " #{idx}: #{cmd}" end)
    |> Enum.join("\n")
  end
end
