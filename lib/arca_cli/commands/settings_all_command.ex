defmodule Arca.CLI.Commands.SettingsAllCommand do
  @moduledoc """
  Arca CLI command to show all settings.
  """
  use Arca.CLI.Command.BaseCommand

  config :"settings.all",
    name: "settings.all",
    about: "Display current configuration settings."

  @doc """
  Show all settings
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, settings, _optimus) do
    inspect(settings, pretty: true)
  end
end