defmodule Arca.Cli.Configurator.ConfiguratorTest.TestCfg8r1 do
  use Arca.Cli.Configurator.BaseConfigurator

  config :arca_cli_testcfg8r1,
    commands: [
      Arca.Cli.Commands.AboutCommand,
      Arca.Cli.Commands.FlushCommand
    ],
    author: "Arca CLI AUTHOR TestCfg8r1",
    about: "Arca CLI ABOUT TestCfg8r1",
    description: "Arca CLI DESCRIPTION TestCfg8r1",
    version: "Arca CLI VERSION TestCfg8r1"
end

defmodule Arca.Cli.Configurator.ConfiguratorTest.TestCfg8r2 do
  use Arca.Cli.Configurator.BaseConfigurator

  config :arca_cli_testcfg8r2,
    commands: [
      Arca.Cli.Commands.FlushCommand,
      Arca.Cli.Commands.GetCommand,
      Arca.Cli.Commands.HistoryCommand
    ],
    author: "Arca CLI AUTHOR TestCfg8r2",
    about: "Arca CLI ABOUT TestCfg8r2",
    description: "Arca CLI DESCRIPTION TestCfg8r2",
    version: "Arca CLI VERSION TestCfg8r2"
end

defmodule Arca.Cli.Configurator.ConfiguratorTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import ExUnit.CaptureLog
  alias Arca.Cli.Commands.AboutCommand
  alias Arca.Cli.Test.Support
  alias Arca.Cli.Configurator.Coordinator
  alias Arca.Cli.Configurator.DftConfigurator
  doctest Arca.Cli.Configurator.ConfiguratorBehaviour
  doctest Arca.Cli.Configurator.BaseConfigurator
  doctest Arca.Cli.Configurator.DftConfigurator

  describe "Arca.Cli.Configurator" do
    setup do
      # Get previous env var for config path and file names
      previous_env = System.get_env()

      # Set up to load the local .arca/arca_cli.json file (using auto-naming)
      test_config_path = "./.arca"
      test_config_file = "arca_cli.json"

      System.put_env("ARCA_CONFIG_PATH", test_config_path)
      System.put_env("ARCA_CONFIG_FILE", test_config_file)

      # Write a known config file to a known location
      # Use the new automatic naming convention
      Support.write_default_config_file(
        test_config_file,
        test_config_path
      )

      # Put things back how we found them
      on_exit(fn -> System.put_env(previous_env) end)

      :ok
    end

    test "CommandBehaviour.config/0 (as AboutCommand)" do
      about_cmd_cfg = AboutCommand.config()
      assert is_list(about_cmd_cfg), "Expected config to be a list"

      assert about_cmd_cfg == [
               about: [
                 name: "about",
                 about: "Info about the command line interface."
               ]
             ]
    end

    test "CommandBehaviour.handle/3 (as AboutCommand)" do
      assert capture_io(fn ->
               Arca.Cli.Commands.AboutCommand.handle()
             end)
             |> String.trim() ==
               """
               📦 Arca CLI
               A declarative CLI for Elixir apps
               https://arca.io
               arca_cli 0.1.0
               """
               |> String.trim()
    end

    test "inject_subcommands/2 can handle addition of multiple command configurations" do
      commands1 = [
        Arca.Cli.Commands.AboutCommand,
        Arca.Cli.Commands.FlushCommand
      ]

      expected_commands1 =
        Arca.Cli.Commands.AboutCommand.config() ++ Arca.Cli.Commands.FlushCommand.config()

      commands2 = [
        Arca.Cli.Commands.GetCommand,
        Arca.Cli.Commands.HistoryCommand
      ]

      expected_commands2 =
        Arca.Cli.Commands.GetCommand.config() ++ Arca.Cli.Commands.HistoryCommand.config()

      optimus_base = [
        name: "name",
        description: "description",
        version: "0.0.1",
        author: "author",
        allow_unknown_args: true,
        parse_double_dash: true,
        subcommands: []
      ]

      optimus =
        optimus_base
        |> DftConfigurator.inject_subcommands(commands1)
        |> DftConfigurator.inject_subcommands(commands2)

      assert Keyword.get(optimus, :subcommands) == expected_commands1 ++ expected_commands2
    end

    test "Coordinator.setup/1 handles single configurator" do
      config = Coordinator.setup(DftConfigurator)
      assert config.name == "arca_cli"
    end

    test "Coordinator.setup/1 handles multiple configurators and warns on duplicates" do
      log =
        capture_log(fn ->
          config =
            Coordinator.setup([
              Arca.Cli.Configurator.ConfiguratorTest.TestCfg8r1,
              # duplicate
              Arca.Cli.Configurator.ConfiguratorTest.TestCfg8r1,
              Arca.Cli.Configurator.ConfiguratorTest.TestCfg8r2
            ])

          assert config.name == "arca_cli_testcfg8r2"
          assert config.author == "Arca CLI AUTHOR TestCfg8r2"
        end)

      assert log =~ "Duplicate configurators found and rejected"
    end
  end
end
