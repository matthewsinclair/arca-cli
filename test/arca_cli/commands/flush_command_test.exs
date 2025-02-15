defmodule Arca.CLI.Command.BaseCommands.FlushCommand.Test do
  use ExUnit.Case
  # import ExUnit.CaptureIO
  alias Arca.CLI.Commands.FlushCommand
  alias Arca.CLI.Test.Support
  doctest Arca.CLI.Commands.FlushCommand

  describe "Arca.CLI.Commands.AboutCommand" do
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

    test "FlushCommand.config/0" do
      about_cmd_cfg = FlushCommand.config()
      assert about_cmd_cfg != nil

      assert about_cmd_cfg == [
               flush: [
                 name: "flush",
                 about: "Flush the command history."
               ]
             ]
    end

    test "FlushCommand.handle/3" do
      assert Arca.CLI.Commands.FlushCommand.handle() == "ok"
    end
  end
end
