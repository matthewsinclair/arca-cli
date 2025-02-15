defmodule Arca.CLI.Test do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Arca.CLI
  alias Arca.CLI.Test.Support
  doctest Arca.CLI

  @cli_commands [
    ["about"],
    ["get", "id"],
    ["help", "settings"],
    ["history"],
    ["redo", "0"],
    ["flush"],
    # ["repl"], # doesn't work as a test as it is interactive
    ["settings"],
    ["status"],
    ["--version"],
    ["--help"]
  ]

  describe "Arca.CLI" do
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

      # Make sure that the CLI State process is running
      # {:ok, _pid} = Arca.CLI.History.start_link()
      :ok
    end

    test "cli commands smoke test" do
      # Run through each command (except 'repl') and smoke test each one
      Enum.each(@cli_commands, fn cmd ->
        IO.puts("\nSmoke testing command: #{Enum.join(cmd, " ")}")

        capture_io(fn ->
          try do
            CLI.main(cmd)
            assert true
          rescue
            e in RuntimeError ->
              IO.puts("error: " <> e.message)
              assert false
          end
        end)
      end)
    end

    test "about" do
      assert capture_io(fn ->
               Arca.CLI.main(["about"])
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

    test "settings" do
      assert capture_io(fn ->
               Arca.CLI.main(["settings"])
             end)
             |> String.trim() ==
               """
               %{"id" => "DOT_SLASH_DOT_LL_SLASH_CONFIG_DOT_JSON"}
               """
               |> String.trim()
    end

    test "get" do
      assert capture_io(fn ->
               Arca.CLI.main(["get"])
             end)
             |> String.trim() ==
               """
               error: get: missing required arguments: SETTING_ID
               """
               |> String.trim()
    end

    test "get id" do
      assert capture_io(fn ->
               Arca.CLI.main(["get", "id"])
             end)
             |> String.trim() ==
               """
               DOT_SLASH_DOT_LL_SLASH_CONFIG_DOT_JSON
               """
               |> String.trim()
    end

    test "help" do
      assert capture_io(fn ->
               Arca.CLI.main(["help"])
             end)
             |> String.trim() ==
               """
               error: invalid subcommand:
               """
               |> String.trim()
    end

    test "help settings" do
      assert capture_io(fn ->
               Arca.CLI.main(["help", "settings"])
             end)
             |> String.trim() ==
               """
               Display current configuration settings.

               USAGE:
                   arca_cli settings
               """
               |> String.trim()
    end

    test "--help" do
      expected_output = """
      USAGE:
          arca_cli ...
          arca_cli --version
          arca_cli --help
          arca_cli help subcommand

      SUBCOMMANDS:

          about           Info about the command line interface.
          flush           Flush the command history.
          get             Get the value of a setting.
          history         Show a history of recent commands.
          redo            Redo a previous command from the history.
          repl            Start the Arca REPL.
          settings        Display current configuration settings.
          status          Show current CLI state.
          sys             Run an OS command from within the CLI and return the
                          results.
      """

      actual_output = capture_io(fn ->
        Arca.CLI.main(["--help"])
      end)
      |> String.trim()

      assert normalize_output(actual_output) == normalize_output(expected_output)
    end

    test "redo out of range" do
      assert capture_io(fn ->
               Arca.CLI.main(["redo", "999"])
             end)
             |> String.trim() ==
               "error: invalid command index: 999"
    end
  end

  defp normalize_output(output) do
    output
    |> String.split("\n")
    |> Enum.map(&String.trim_trailing/1)
    |> Enum.join("\n")
    |> String.trim()
  end
end
