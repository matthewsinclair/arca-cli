defmodule Arca.Cli.Commands.Test1Command do
  use Arca.Cli.Command.BaseCommand

  config :test1,
    name: "test1",
    about: "A test function for the test1 command"
end

defmodule Arca.Cli.Commands.Test2Command do
  use Arca.Cli.Command.BaseCommand

  config :test2,
    name: "test2",
    about: "A test function for the test2 command"

  def handle(args, settings, optimus) do
    {:ok, [args, settings, optimus]}
  end
end

defmodule Arca.Cli.Command.BaseCommand.Test do
  use ExUnit.Case
  # import ExUnit.CaptureIO
  alias Arca.Cli.Test.Support
  doctest Arca.Cli.Command.BaseCommand

  describe "Arca.Cli.Command.BaseCommand" do
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


    test "Arca.Cli.Command.BaseCommand" do
      # Exists (smoke test for compilation)
      assert Arca.Cli.Command.BaseCommand
      assert Arca.Cli.Commands.Test1Command
      assert Arca.Cli.Commands.Test2Command

      # TestCommand1 functions are exported
      assert function_exported?(Arca.Cli.Commands.Test1Command, :config, 0)
      assert function_exported?(Arca.Cli.Commands.Test1Command, :handle, 3)

      # TestCommand1.config/0 returns what we expect
      assert Arca.Cli.Commands.Test1Command.config() == [
               test1: [
                 name: "test1",
                 about: "A test function for the test1 command"
               ]
             ]

      # TestCommand2.config/0 returns what we expect
      assert Arca.Cli.Commands.Test2Command.config() == [
               test2: [
                 name: "test2",
                 about: "A test function for the test2 command"
               ]
             ]

      # TestCommand1.handle/3 returns what we expect for TestCommand1
      assert {:error, _} = Arca.Cli.Commands.Test1Command.handle()

      # TestCommand2.handle/3 returns what we expect for TestCommand2
      assert {:ok, _} = Arca.Cli.Commands.Test2Command.handle()

      # Just be sure that the dft params are working for TestCommand2
      {:ok, [a1, a2, a3]} = Arca.Cli.Commands.Test2Command.handle()
      assert {a1, a2, a3} == {nil, nil, nil}
      {:ok, ["one", b2, b3]} = Arca.Cli.Commands.Test2Command.handle("one")
      assert {b2, b3} == {nil, nil}
      {:ok, ["one", "two", c3]} = Arca.Cli.Commands.Test2Command.handle("one", "two")
      assert c3 == nil
      {:ok, ["one", "two", "three"]} = Arca.Cli.Commands.Test2Command.handle("one", "two", "three")
      assert true
    end
  end
end
