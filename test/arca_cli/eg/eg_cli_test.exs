# ----
# Everything required for a mimimal Arca.CLI example app.
# ----

defmodule Eg.CLI do
  @moduledoc """
  A simple example CLI that uses Arca.CLI.
  """

  @doc """
  Entry point for command line parsing (just pass up to Arca.CLI).
  """
  def main(argv) do
    Arca.CLI.main(argv)
  end
end

defmodule Eg.CLI.EgCommand do
  @moduledoc """
  A simple example command to test Arca.CLI commands.
  """
  import Arca.CLI.Utils
  use Arca.CLI.Command.BaseCommand

  config :eg,
    name: "eg",
    about: "An example command"

  @doc """
  Ech the name of the command.
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    Arca.CLI.Utils.this_fn_as_string()
  end
end

defmodule Eg.CLI.EgwithparamCommand do
  @moduledoc """
  A simple example command to test Arca.CLI commands with params.
  """
  use Arca.CLI.Command.BaseCommand

  config :egwithparam,
    name: "egwithparam",
    about: "An example command with a paramater",
    args: [
      p1: [
        value_name: "P1",
        help: "A paramater to pass to the example command",
        required: true,
        parser: :string
      ]
    ]

  @doc """
  Return the paramater passed into the example command
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(args, _settings, _optimus) do
    Arca.CLI.Utils.this_fn_as_string(args.args.p1)
  end
end

defmodule Eg.CLI.EgsubCommand do
  @moduledoc """
  A simple example command to test Arca.CLI nested sub-commands.
  """
  import Arca.CLI.Utils
  use Arca.CLI.Command.BaseCommand
  use Arca.CLI.Command.BaseSubCommand

  config :egsub,
    name: "egsub",
    about: "An example nested sub command",
    args: [
      cmd: [
        value_name: "CMD",
        help: "one | two | ...",
        required: true,
        parser: :string
      ],
      args: [
        value_name: "ARGS",
        help: "*",
        required: false,
        parser: :string
      ]
    ],
    sub_commands: [
      Eg.CLI.EgsuboneCommand
    ]
end

defmodule Eg.CLI.EgsuboneCommand do
  @moduledoc """
  A simple example command to test Arca.CLI sub commands.
  """
  use Arca.CLI.Command.BaseCommand
  import Arca.CLI.Utils

  config :egsubone,
    name: "egsubone",
    about: "Sub one.",
    args: [
      p1: [
        value_name: "p1",
        help: "Parameter One",
        required: false,
        parser: :string
      ]
    ]

  @doc """
  SuboneCommand
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(args, _settings, _optimus) do
    this_fn_as_string(args.p1)
  end
end


defmodule Eg.CLI.EgConfigurator do
  @moduledoc """
  `Eg.CLI.Commands.Configurator` sets up the Eg.CLI commands in a Configurator.
  """
  use Arca.CLI.Configurator.BaseConfigurator

  config :eg_cli,
    commands: [
      Eg.CLI.EgCommand,
      Eg.CLI.EgwithparamCommand,
      Eg.CLI.EgsubCommand
    ],
    author: "hello@eg.cli",
    about: "The simplest Arca CLI Example",
    description: "eg_cli is the simplest, fully worked Arca CLI example",
    version: "0.0.1"
end

# ----
# Test the mimimal Arca.CLI example app.
# ----

defmodule Eg.CLI.Test do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @cli_commands [
    ["eg"],
    ["egwithparam", "p1"],
    ["egsub", "egsubone", "p1"]
  ]

  describe "Eg.CLI" do
    setup do
      # Get previous env var for config path and file names
      previous_configurators = Application.get_env(:arca_cli, :configurators)

      Application.put_env(:arca_cli, :configurators, [
        Eg.CLI.EgConfigurator
      ])

      # Put things back how we found them
      on_exit(fn -> Application.put_env(:arca_cli, :configurators, previous_configurators) end)

      :ok
    end

    test "eg_cli commands smoke test" do
      # Expected results for each command
      expected_output = %{
        "eg" => "Eg.CLI.EgCommand.handle/3",
        "egwithparam" => "Eg.CLI.EgwithparamCommand.handle/3: p1",
        "egsub" => "Eg.CLI.EgsuboneCommand.handle/3: p1"
      }

      # Run through each command and smoke test each one
      Enum.each(@cli_commands, fn cmd ->
        [cmd_string | _] = cmd
        IO.puts("\nSmoke testing example command: #{Enum.join(cmd, " ")}")

        res = capture_io(fn ->
          try do
            Eg.CLI.main(cmd)
          rescue
            e in RuntimeError ->
              IO.puts("error: " <> e.message)
              assert false
          end
        end) |> String.trim()
        assert Map.get(expected_output, cmd_string) =~ res
      end)
    end
  end
end
