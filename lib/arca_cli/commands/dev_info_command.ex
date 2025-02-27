defmodule Arca.Cli.Commands.DevInfoCommand do
  @moduledoc """
  Command to display development environment information.
  This is a namespaced command using dot notation (dev.info).
  """
  use Arca.Cli.Command.BaseCommand

  config :"dev.info",
    name: "dev.info",
    about: "Display development environment information."

  @impl Arca.Cli.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    """
    Development Environment Information:
    Mix Environment: #{Mix.env()}
    Project Name: #{Mix.Project.config()[:app]}
    Project Version: #{Mix.Project.config()[:version]}
    Elixir Path: #{System.find_executable("elixir")}
    Compilation Target: #{:erlang.system_info(:system_architecture)}
    """
  end
end
