defmodule Arca.CLI.Configurator.DftConfigurator do
  @moduledoc """
  `Arca.CLI.Configurator.DftConfigurator` is a default implementation of the ConfiguratorBehaviour (using BaseConfigurator) that configures the CLI to use the basic predefined commands.
  """
  use Arca.CLI.Configurator.BaseConfigurator

  config :arca_cli,
    commands: [
      # Alphabetically ordered commands
      Arca.CLI.Commands.AboutCommand,
      Arca.CLI.Commands.CliHistoryCommand,   # history -> cli.history
      Arca.CLI.Commands.CliRedoCommand,      # redo -> cli.redo
      Arca.CLI.Commands.CliStatusCommand,    # status -> cli.status
      Arca.CLI.Commands.ReplCommand,         # stays the same
      Arca.CLI.Commands.SettingsAllCommand,  # settings -> settings.all
      Arca.CLI.Commands.SettingsGetCommand,  # get -> settings.get
      Arca.CLI.Commands.SysCmdCommand,       # sys -> sys.cmd
      Arca.CLI.Commands.SysFlushCommand,     # flush -> sys.flush
      Arca.CLI.Commands.SysInfoCommand       # stays the same

      # This is just a test of a SubCommand. See Eg.CLI.Test for a better example.
      # Arca.CLI.Commands.SubCommand
    ],
    author: "Arca CLI AUTHOR",
    about: "Arca CLI ABOUT",
    description: "Arca CLI DESCRIPTION",
    version: "Arca CLI VERSION"
end
