defmodule Arca.CLI.Configurator.DftConfigurator do
  @moduledoc """
  `Arca.CLI.Configurator.DftConfigurator` is a default implementation of the ConfiguratorBehaviour (using BaseConfigurator) that configures the CLI to use the basic predefined commands.
  """
  use Arca.CLI.Configurator.BaseConfigurator

  config :arca_cli,
    commands: [
      Arca.CLI.Commands.AboutCommand,
      Arca.CLI.Commands.FlushCommand,
      Arca.CLI.Commands.GetCommand,
      Arca.CLI.Commands.HistoryCommand,
      Arca.CLI.Commands.RedoCommand,
      Arca.CLI.Commands.ReplCommand,
      Arca.CLI.Commands.SettingsCommand,
      Arca.CLI.Commands.StatusCommand,
      Arca.CLI.Commands.SysCommand

      # This is just a test of a SubCommand. See Eg.CLI.Test for a better example.
      # Arca.CLI.Commands.SubCommand
    ],
    author: "Arca CLI AUTHOR",
    about: "Arca CLI ABOUT",
    description: "Arca CLI DESCRIPTION",
    version: "Arca CLI VERSION"
end
