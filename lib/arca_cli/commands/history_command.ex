defmodule Arca.CLI.Commands.HistoryCommand do
  @moduledoc """
  Show history of previous commands.
  """
  use Arca.CLI.Command.BaseCommand

  config :history,
    name: "history",
    about: "Show a history of recent commands."

  @doc """
  Show history of previous commands.
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    Arca.CLI.History.history()
    |> format_history_list()
  end

  defp format_history_list(history_list)

  defp format_history_list([{history_id, history_cmd} | tail]) do
    String.pad_leading(Integer.to_string(history_id), signif_digits(history_id), "0") <>
      ": #{history_cmd}\n" <> format_history_list(tail)
  end

  defp format_history_list([]), do: ""

  defp signif_digits(number) do
    number |> Integer.digits() |> length
  end
end
