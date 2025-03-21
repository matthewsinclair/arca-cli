defmodule Arca.Cli.Commands.SettingsAllCommand do
  @moduledoc """
  Displays all current configuration settings.

  This command provides a formatted view of all application settings,
  showing the complete configuration state.
  """
  use Arca.Cli.Command.BaseCommand

  config :"settings.all",
    name: "settings.all",
    about: "Display current configuration settings."

  @typedoc """
  Possible error types for settings display operations
  """
  @type error_type ::
          :formatting_error
          | :empty_settings
          | :internal_error

  @typedoc """
  Result type for settings operations
  """
  @type result(t) :: {:ok, t} | {:error, error_type(), String.t()}

  @doc """
  Format and display all settings.

  This implementation uses Railway-Oriented Programming to handle the
  formatting and display of settings.
  """
  @impl Arca.Cli.Command.CommandBehaviour
  @spec handle(map(), map(), Optimus.t()) :: String.t()
  def handle(_args, settings, _optimus) do
    with {:ok, valid_settings} <- validate_settings(settings),
         {:ok, formatted} <- format_settings(valid_settings) do
      formatted
    else
      {:error, :empty_settings, message} ->
        message

      {:error, _error_type, message} ->
        message
    end
  end

  # Validate that settings are not empty
  @spec validate_settings(map()) :: result(map())
  defp validate_settings(settings) do
    if is_map(settings) && map_size(settings) > 0 do
      {:ok, settings}
    else
      {:error, :empty_settings, "No settings available"}
    end
  end

  # Format the settings map for display
  @spec format_settings(map()) :: result(String.t())
  defp format_settings(settings) do
    try do
      formatted = inspect(settings, pretty: true)
      {:ok, formatted}
    rescue
      e ->
        {:error, :formatting_error, "Failed to format settings: #{inspect(e)}"}
    end
  end
end
