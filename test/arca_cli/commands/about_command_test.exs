defmodule Arca.CLI.Commands.AboutCommand.Test do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Arca.CLI.Commands.AboutCommand
  alias Arca.CLI.Test.Support
  doctest Arca.CLI.Commands.AboutCommand

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

    test "AboutCommand.config/0" do
      about_cmd_cfg = AboutCommand.config()
      assert about_cmd_cfg != nil

      assert about_cmd_cfg == [
               about: [
                 name: "about",
                 about: "Info about the command line interface."
               ]
             ]
    end

    test "AboutCommand.handle/3" do
      assert capture_io(fn ->
               Arca.CLI.Commands.AboutCommand.handle()
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
  end
end
