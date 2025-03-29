defmodule Arca.Cli.Commands.AboutCommandTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Arca.Cli.Commands.AboutCommand
  alias Arca.Cli.Test.Support
  doctest Arca.Cli.Commands.AboutCommand

  describe "Arca.Cli.Commands.AboutCommand" do
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
      assert is_list(about_cmd_cfg), "Expected config to be a list"

      # Extract the config for about command
      [about: config_opts] = about_cmd_cfg

      # Check required fields exist
      assert Keyword.get(config_opts, :name) == "about"
      assert Keyword.get(config_opts, :about) == "Info about the command line interface."

      # Help field is optional but should be a string if present
      help_text = Keyword.get(config_opts, :help)
      if help_text, do: assert(is_binary(help_text))
    end

    test "AboutCommand.handle/3" do
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
  end
end
