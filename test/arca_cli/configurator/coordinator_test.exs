defmodule Arca.CLI.Configurator.CoordinatorTest.TestCfg8r1 do
  use Arca.CLI.Configurator.BaseConfigurator

  config :arca_cli_testcfg8r1,
    commands: [
      Arca.CLI.Commands.AboutCommand,
      Arca.CLI.Commands.FlushCommand,
    ],
    author: "Arca CLI AUTHOR TestCfg8r1",
    about: "Arca CLI ABOUT TestCfg8r1",
    description: "Arca CLI DESCRIPTION TestCfg8r1",
    version: "Arca CLI VERSION TestCfg8r1"
end

defmodule Arca.CLI.Configurator.CoordinatorTest.TestCfg8r2 do
  use Arca.CLI.Configurator.BaseConfigurator

  config :arca_cli_testcfg8r2,
    commands: [
      Arca.CLI.Commands.FlushCommand,
      Arca.CLI.Commands.GetCommand,
      Arca.CLI.Commands.HistoryCommand
    ],
    author: "Arca CLI AUTHOR TestCfg8r2",
    about: "Arca CLI ABOUT TestCfg8r2",
    description: "Arca CLI DESCRIPTION TestCfg8r2",
    version: "Arca CLI VERSION TestCfg8r2"
end

defmodule Arca.CLI.Configurator.Coordinator.Test do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Arca.CLI.Configurator.Coordinator
  alias Arca.CLI.Configurator.DftConfigurator
  alias Arca.CLI.Test.Support

  doctest Arca.CLI.Configurator.Coordinator

  describe "Arca.CLI.Configurator.Coordinator" do
    setup do
      # Get previous env var for config path and file names
      previous_env = System.get_env()

      # Set up to load the local .arca/config.json file
      System.put_env("ARCA_CONFIG_PATH", "./.arca")
      System.put_env("ARCA_CONFIG_FILE", "config.json")

      # Write a known config file to a known location
      Support.write_default_config_file(
        System.get_env("ARCA_CONFIG_FILE"),
        System.get_env("ARCA_CONFIG_PATH")
      )

      # Put things back how we found them
      on_exit(fn -> System.put_env(previous_env) end)

      :ok
    end

    test "Coordinator.setup/0 uses default configurator" do
      config = Coordinator.setup()
      assert config.name == "arca_cli"
    end

    test "Coordinator.setup/1 handles single configurator" do
      config = Coordinator.setup(DftConfigurator)
      assert config.name == "arca_cli"
    end

    test "Coordinator.setup/1 handles multiple configurators" do
      config = Coordinator.setup([
        Arca.CLI.Configurator.CoordinatorTest.TestCfg8r1,
        Arca.CLI.Configurator.CoordinatorTest.TestCfg8r2
      ])
      assert config.name == "arca_cli_testcfg8r2"
      assert config.author == "Arca CLI AUTHOR TestCfg8r2"
    end

    test "Coordinator.setup/1 rejects duplicate configurators and logs warning" do
      log = capture_log(fn ->
        config = Coordinator.setup([
          Arca.CLI.Configurator.CoordinatorTest.TestCfg8r1,
          Arca.CLI.Configurator.CoordinatorTest.TestCfg8r1,  # duplicate
          Arca.CLI.Configurator.CoordinatorTest.TestCfg8r2
        ])
        assert config.name == "arca_cli_testcfg8r2"
        assert config.author == "Arca CLI AUTHOR TestCfg8r2"
      end)
      assert log =~ "Duplicate configurators found and rejected"
    end

    test "Coordinator.setup/1 logs warning for duplicate subcommand names" do
      log = capture_log(fn ->
        config = Coordinator.setup([
          Arca.CLI.Configurator.CoordinatorTest.TestCfg8r1,
          Arca.CLI.Configurator.CoordinatorTest.TestCfg8r2
        ])
        assert config.name == "arca_cli_testcfg8r2"
        assert config.author == "Arca CLI AUTHOR TestCfg8r2"
      end)
      assert log =~ "Duplicate subcommand names found"
    end
  end
end
