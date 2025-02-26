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
    settings = Cli.load_settings()

    if map_size(settings) == 0 do
      {:error, "problem with config settings"}
    else
      settings
    end
  end
end
