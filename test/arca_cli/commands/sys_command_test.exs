defmodule Arca.Cli.Commands.SysCommandTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Arca.Cli.Commands.SysCommand
  alias Arca.Cli.Test.Support

  doctest Arca.Cli.Commands.SysCommand

  describe "Arca.Cli.Commands.SysCommand" do
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

    test "SysCommand.config/0 returns correct config" do
      expected_config = [
        sys: [
          name: "sys",
          about: "Run an OS command from within the CLI and return the results.",
          allow_unknown_args: true,
          args: [
            args: [
              value_name: "ARGS",
              help: "Arguments to OS command",
              required: false,
              parser: :string
            ]
          ]
        ]
      ]

      assert SysCommand.config() == expected_config
    end

    test "SysCommand.handle/3 runs command without unknown args" do
      args = %{args: %{args: "pwd"}, unknown: []}
      expected_output = System.cmd("pwd", [])

      assert capture_io(fn ->
               assert SysCommand.handle(args, nil, nil) == expected_output
             end) == elem(expected_output, 0)
    end

    test "SysCommand.handle/3 runs command with unknown args" do
      args = %{args: %{args: "echo"}, unknown: ["hello world"]}
      expected_output = System.cmd("echo", ["hello world"])

      assert capture_io(fn ->
               assert SysCommand.handle(args, nil, nil) == expected_output
             end) == elem(expected_output, 0)
    end

    test "SysCommand.handle/3 handles command errors" do
      args = %{args: %{args: "nonexistentcommand"}, unknown: []}

      # assert capture_io(fn ->
      {error, _reason} = SysCommand.handle(args, nil, nil)
      assert error =~ "nonexistentcommand"
      #  end)
    end
  end
end
