defmodule Arca.Cli.Configurator.DftConfigurator do
  @moduledoc """
  `Arca.Cli.Configurator.DftConfigurator` is a default implementation of the ConfiguratorBehaviour (using BaseConfigurator) that configures the CLI to use the basic predefined commands.
  """
  use Arca.Cli.Configurator.BaseConfigurator

  config :arca_cli,
    commands: [
      Arca.Cli.Commands.AboutCommand,
      Arca.Cli.Commands.CliHistoryCommand,
      Arca.Cli.Commands.CliDebugCommand,
      Arca.Cli.Commands.CliErrorCommand,
      Arca.Cli.Commands.CliRedoCommand,
      Arca.Cli.Commands.CliScriptCommand,
      Arca.Cli.Commands.CliStatusCommand,
      Arca.Cli.Commands.DevInfoCommand,
      Arca.Cli.Commands.DevDepsCommand,
      Arca.Cli.Commands.CfgListCommand,
      Arca.Cli.Commands.CfgGetCommand,
      Arca.Cli.Commands.CfgHelpCommand,
      Arca.Cli.Commands.ReplCommand,
      Arca.Cli.Commands.SettingsAllCommand,
      Arca.Cli.Commands.SettingsGetCommand,
      Arca.Cli.Commands.SysCmdCommand,
      Arca.Cli.Commands.SysFlushCommand,
      Arca.Cli.Commands.SysInfoCommand,
      Arca.Cli.Commands.DbgEchoCommand,
      Arca.Cli.Commands.DbgTokensCommand

      # This is just a test of a SubCommand. See Eg.Cli.Test for a better example.
      # Arca.Cli.Commands.SubCommand
    ],
    author: "Arca CLI AUTHOR",
    about: "Arca CLI ABOUT",
    description: "Arca CLI DESCRIPTION",
    version: "Arca CLI VERSION"
end
