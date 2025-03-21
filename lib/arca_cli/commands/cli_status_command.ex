defmodule Arca.Cli.Commands.CliStatusCommand do
  @moduledoc """
  Displays the current state of the CLI application.

  This command provides a summary of the application's state, including
  the command history and current settings.
  """
  alias Arca.Cli.History
  use Arca.Cli.Command.BaseCommand

  config :"cli.status",
    name: "cli.status",
    about: "Show current CLI state."

  @typedoc """
  Possible error types for status operations
  """
  @type error_type ::
          :history_unavailable
          | :formatting_error

  @typedoc """
  Result type for status operations
  """
  @type result(t) :: {:ok, t} | {:error, error_type(), String.t()}

  @doc """
  Display CLI state information with proper error handling.

  Uses Railway-Oriented Programming to gather and format status information.
  """
  @impl Arca.Cli.Command.CommandBehaviour
  @spec handle(map(), map(), Optimus.t()) :: String.t()
  def handle(_args, settings, _optimus) do
    with {:ok, history_count} <- get_history_count(),
         {:ok, formatted_settings} <- format_settings(settings),
         {:ok, status} <- format_status(history_count, formatted_settings) do
      status
    else
      {:error, :history_unavailable, message} ->
        "Error retrieving history: #{message}\nSettings: #{inspect(settings)}"

      {:error, :formatting_error, message} ->
        "Error formatting status: #{message}"
    end
  end

  @doc """
  Get the current history entry count with error handling.

  ## Returns
    - {:ok, count} with the number of history entries
    - {:error, error_type, reason} if history unavailable
  """
  @spec get_history_count() :: result(non_neg_integer())
  def get_history_count() do
    try do
      count = History.hlen()
      {:ok, count}
    rescue
      e ->
        {:error, :history_unavailable, "#{inspect(e)}"}
    end
  end

  @doc """
  Format settings for display with error handling.

  ## Parameters
    - settings: Application settings map
    
  ## Returns
    - {:ok, formatted} with the formatted settings string
    - {:error, error_type, reason} on formatting failure
  """
  @spec format_settings(map()) :: result(String.t())
  def format_settings(settings) do
    try do
      formatted = inspect(settings)
      {:ok, formatted}
    rescue
      e ->
        {:error, :formatting_error, "Failed to format settings: #{inspect(e)}"}
    end
  end

  @doc """
  Combine history count and settings into a status report.

  ## Parameters
    - history_count: Number of history entries
    - formatted_settings: Formatted settings string
    
  ## Returns
    - {:ok, status} with the complete status report
    - {:error, error_type, reason} on formatting failure
  """
  @spec format_status(non_neg_integer(), String.t()) :: result(String.t())
  def format_status(history_count, formatted_settings) do
    try do
      status =
        [
          "History entries: #{history_count}",
          "Settings: #{formatted_settings}"
        ]
        |> Enum.join("\n")

      {:ok, status}
    rescue
      _ ->
        {:error, :formatting_error, "Failed to format status report"}
    end
  end
end
