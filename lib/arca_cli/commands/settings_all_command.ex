defmodule Arca.Cli.Commands.SettingsAllCommand do
  @moduledoc """
  Arca CLI command to show all settings.
  """
  use Arca.Cli.Command.BaseCommand

  config :"settings.all",
    name: "settings.all",
    about: "Display current configuration settings."

  @doc """
  Show all settings
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(_args, settings, _optimus) do
    inspect(settings, pretty: true)
  end
end
