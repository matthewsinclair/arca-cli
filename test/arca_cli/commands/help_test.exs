defmodule Arca.Cli.HelpTest do
  use ExUnit.Case, async: false

  alias Arca.Cli.Help
  alias Arca.Cli.Commands.SysFlushCommand

  describe "help behavior with existing commands" do
    test "show_help? returns false for SysFlushCommand with empty args" do
      # SysFlush doesn't require args, so it shouldn't show help on empty args
      refute Help.show_help_on_empty?(SysFlushCommand)
      refute Help.should_show_help?(:"sys.flush", %{}, SysFlushCommand)
    end

    test "show_help? returns true for any command with --help flag" do
      # Help flag should always show help regardless of command
      assert Help.should_show_help?(:"sys.flush", ["--help"], SysFlushCommand)
    end

    test "commands can control help behavior with show_help_on_empty" do
      # Define a test module to simulate a command with show_help_on_empty: true
      defmodule TestCommandWithHelp do
        def config do
          [test: [show_help_on_empty: true]]
        end
      end

      # Define a test module to simulate a command without show_help_on_empty
      defmodule TestCommandWithoutHelp do
        def config do
          [test: []]
        end
      end

      # Verify that the help module correctly detects the flag
      assert Help.show_help_on_empty?(TestCommandWithHelp)
      refute Help.show_help_on_empty?(TestCommandWithoutHelp)
    end
  end

  describe "help flag detection" do
    test "has_help_flag? returns true for args list with --help" do
      assert Help.has_help_flag?(["--help"])
    end

    test "has_help_flag? returns true for Optimus.ParseResult with help flag" do
      args = %Optimus.ParseResult{args: %{}, flags: %{help: true}, options: %{}}
      assert Help.has_help_flag?(args)
    end

    test "has_help_flag? returns false for args without --help" do
      refute Help.has_help_flag?(%{options: %{foo: "bar"}})
    end

    test "has_help_flag? returns false for empty args" do
      refute Help.has_help_flag?(%{})
    end
  end

  describe "empty args detection" do
    test "is_empty_command_args? returns true for empty map" do
      assert Help.is_empty_command_args?(%{})
    end

    test "is_empty_command_args? returns true for empty Optimus.ParseResult" do
      args = %Optimus.ParseResult{args: %{}, flags: %{}, options: %{}}
      assert Help.is_empty_command_args?(args)
    end

    test "is_empty_command_args? returns true for [\"--help\"]" do
      assert Help.is_empty_command_args?(["--help"])
    end

    test "is_empty_command_args? returns false for non-empty args" do
      refute Help.is_empty_command_args?(%{args: %{id: "some.setting"}})
    end
  end
end
