defmodule Arca.Cli.Commands.CliScriptCommand do
  @moduledoc """
  Processes a script file and executes each line as an Arca CLI command.

  This command allows users to run multiple CLI commands from a file, with each line
  in the file treated as if it were entered directly at the CLI prompt.

  Lines starting with '#' are treated as comments and ignored.
  """

  alias Arca.Cli.Repl
  use Arca.Cli.Command.BaseCommand

  config :"cli.script",
    name: "cli.script",
    about: "Run commands from a script file",
    args: [
      file: [
        value_name: "FILE",
        help: "Path to script file containing CLI commands",
        required: true,
        parser: :string
      ]
    ]

  @doc """
  Execute commands from a script file.

  The function reads the file line by line, and processes each line as follows:
  - Lines starting with '#' are treated as comments and ignored
  - Empty lines are ignored
  - Other lines are executed as CLI commands

  ## Parameters
  - `args`: Command arguments (contains the script file path)
  - `settings`: Application settings
  - `optimus`: Command line parser configuration

  ## Returns
  - Result of the last command or error message
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(args, settings, optimus) do
    file_path = args.args.file

    case File.read(file_path) do
      {:ok, file_contents} ->
        # Process the script and return without any additional output
        process_script_commands(file_contents, settings, optimus)
        # Return with no output - commands have already produced their output
        {:nooutput, :ok}

      {:error, reason} ->
        "Error reading script file: #{inspect(reason)}"
    end
  end

  @doc """
  Process each line in the script file as a CLI command.

  ## Parameters
  - `file_contents`: Contents of the script file
  - `settings`: Application settings
  - `optimus`: Command line parser configuration

  ## Returns
  - :ok (primarily operates through side effects)
  """
  @spec process_script_commands(String.t(), map(), term()) :: :ok
  def process_script_commands(file_contents, settings, optimus) do
    lines = String.split(file_contents, ~r/\r?\n/)

    lines
    |> Enum.each(fn line ->
      trimmed_line = String.trim(line)

      cond do
        # Skip empty lines
        trimmed_line == "" ->
          :ok

        # Skip comment lines
        String.starts_with?(trimmed_line, "#") ->
          :ok

        # Process command lines
        true ->
          # Print the command with a nice prefix
          IO.puts("\nscript> #{trimmed_line}")

          # Simulate REPL input by using the same approach as cli.redo
          Repl.eval_for_redo({0, trimmed_line}, settings, optimus)
          |> Repl.print_result()
      end
    end)

    :ok
  end
end
