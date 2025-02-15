defmodule Arca.CLI.Commands.SettingsCommand do
  @moduledoc """
  Arca CLI command to get all settings.
  """
  alias Arca.CLI
  use Arca.CLI.Command.BaseCommand

  config :settings,
    name: "settings",
    about: "Display current configuration settings."

  @doc """
  Get all settings.
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    settings = CLI.load_settings()

    if map_size(settings) == 0 do
      {:error, "problem with config settings"}
    else
      settings
    end
  end
end
