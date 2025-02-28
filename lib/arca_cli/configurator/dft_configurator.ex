defmodule Arca.Cli.Configurator.DftConfigurator do
  @moduledoc """
  `Arca.Cli.Configurator.DftConfigurator` is a default implementation of the ConfiguratorBehaviour (using BaseConfigurator) that configures the CLI to use the basic predefined commands.
  """
  use Arca.Cli.Configurator.BaseConfigurator

  config :arca_cli,
    commands: [
      # Alphabetically ordered commands
      Arca.Cli.Commands.AboutCommand,
      # history -> cli.history
      Arca.Cli.Commands.CliHistoryCommand,
      # redo -> cli.redo
      Arca.Cli.Commands.CliRedoCommand,
      # status -> cli.status
      Arca.Cli.Commands.CliStatusCommand,
      # dev.info
      Arca.Cli.Commands.DevInfoCommand,
      # dev.deps
      Arca.Cli.Commands.DevDepsCommand,
      # config.list
      Arca.Cli.Commands.ConfigListCommand,
      # config.get
      Arca.Cli.Commands.ConfigGetCommand,
      # config.help
      Arca.Cli.Commands.ConfigHelpCommand,
      # stays the same
      Arca.Cli.Commands.ReplCommand,
      # settings -> settings.all
      Arca.Cli.Commands.SettingsAllCommand,
      # get -> settings.get
      Arca.Cli.Commands.SettingsGetCommand,
      # sys -> sys.cmd
      Arca.Cli.Commands.SysCmdCommand,
      # flush -> sys.flush
      Arca.Cli.Commands.SysFlushCommand,
      # stays the same
      Arca.Cli.Commands.SysInfoCommand,
      # Debug command for parameter echo testing
      Arca.Cli.Commands.DbgEchoCommand,
      # Debug command for token analysis
      Arca.Cli.Commands.DbgTokensCommand

      # This is just a test of a SubCommand. See Eg.Cli.Test for a better example.
      # Arca.Cli.Commands.SubCommand
    ],
    author: "Arca CLI AUTHOR",
    about: "Arca CLI ABOUT",
    description: "Arca CLI DESCRIPTION",
    version: "Arca CLI VERSION"
end
