defmodule Arca.Cli.Commands.SettingsCommand do
  @moduledoc """
  Arca CLI command to get all settings.
  """
  alias Arca.Cli
  use Arca.Cli.Command.BaseCommand

  config :settings,
    name: "settings",
    about: "Display current configuration settings."

  @doc """
  Get all settings.
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    # Use a simpler approach that satisfies the type checker
    result = Cli.load_settings()

    # Explicitly handle each possible return type
    case result do
      {:ok, settings} ->
        if map_size(settings) == 0 do
          {:error, "problem with config settings"}
        else
          settings
        end

      # This is intentionally here for future compatibility,
      # even though the type checker might not recognize it
      _ ->
        {:error, "Failed to load settings"}
    end
  end
end
