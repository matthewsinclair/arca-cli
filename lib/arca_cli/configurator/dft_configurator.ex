defmodule Arca.Cli.Configurator.DftConfigurator do
  @moduledoc """
  `Arca.Cli.Configurator.DftConfigurator` is a default implementation of the ConfiguratorBehaviour (using BaseConfigurator) that configures the CLI to use the basic predefined commands.
  """
  use Arca.Cli.Configurator.BaseConfigurator

  config :arca_cli,
    commands: [
      # Alphabetically ordered commands
      Arca.Cli.Commands.AboutCommand,
      Arca.Cli.Commands.CliHistoryCommand,   # history -> cli.history
      Arca.Cli.Commands.CliRedoCommand,      # redo -> cli.redo
      Arca.Cli.Commands.CliStatusCommand,    # status -> cli.status
      Arca.Cli.Commands.DevInfoCommand,      # dev.info
      Arca.Cli.Commands.DevDepsCommand,      # dev.deps
      Arca.Cli.Commands.ConfigListCommand,   # config.list
      Arca.Cli.Commands.ConfigGetCommand,    # config.get
      Arca.Cli.Commands.ConfigHelpCommand,   # config.help
      Arca.Cli.Commands.ReplCommand,         # stays the same
      Arca.Cli.Commands.SettingsAllCommand,  # settings -> settings.all
      Arca.Cli.Commands.SettingsGetCommand,  # get -> settings.get
      Arca.Cli.Commands.SysCmdCommand,       # sys -> sys.cmd
      Arca.Cli.Commands.SysFlushCommand,     # flush -> sys.flush
      Arca.Cli.Commands.SysInfoCommand       # stays the same

      # This is just a test of a SubCommand. See Eg.Cli.Test for a better example.
      # Arca.Cli.Commands.SubCommand
    ],
    author: "Arca CLI AUTHOR",
    about: "Arca CLI ABOUT",
    description: "Arca CLI DESCRIPTION",
    version: "Arca CLI VERSION"
end
