defmodule Arca.Cli.Commands.CliScriptCommand do
  @moduledoc """
  Processes a script file and executes each line as an Arca CLI command.

  This command allows users to run multiple CLI commands from a file, with each line
  in the file treated as if it were entered directly at the CLI prompt.

  Lines starting with '#' are treated as comments and ignored.

  ## Heredoc Support

  Commands can include heredoc-style stdin injection:

      command <<EOF
      line 1
      line 2
      EOF

  Each line in the heredoc is provided to the command's stdin as if typed interactively.
  """

  alias Arca.Cli.Commands.InputProvider
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

  Parses the script to extract commands (including heredoc syntax), then executes each.

  ## Parameters
  - `file_contents`: Contents of the script file
  - `settings`: Application settings
  - `optimus`: Command line parser configuration

  ## Returns
  - :ok or raises on parse error
  """
  @spec process_script_commands(String.t(), map(), term()) :: :ok
  def process_script_commands(file_contents, settings, optimus) do
    file_contents
    |> parse_script()
    |> handle_parse_result(settings, optimus)
  end

  # Parser - extract commands with optional heredoc stdin

  defp parse_script(content) do
    content
    |> String.split(~r/\r?\n/)
    |> parse_lines([], :normal, 1)
  end

  # Parse complete - return accumulated commands
  defp parse_lines([], acc, :normal, _line_num) do
    {:ok, Enum.reverse(acc)}
  end

  # Parse complete but heredoc unclosed - error
  defp parse_lines([], _acc, {:in_heredoc, _cmd, marker, _lines, start_line}, _line_num) do
    {:error, {:unclosed_heredoc, marker, start_line}}
  end

  # Parse next line in normal mode
  defp parse_lines([line | rest], acc, :normal, line_num) do
    line
    |> String.trim()
    |> classify_line()
    |> handle_classification(line, rest, acc, line_num)
  end

  # Parse next line in heredoc mode
  defp parse_lines([line | rest], acc, {:in_heredoc, cmd, marker, lines, start_line}, line_num) do
    line
    |> String.trim()
    |> check_heredoc_end(marker)
    |> handle_heredoc_line(line, rest, acc, cmd, marker, lines, start_line, line_num)
  end

  # Classify line type in normal mode
  defp classify_line(""), do: :skip
  defp classify_line("#" <> _), do: :skip

  defp classify_line(trimmed) do
    case Regex.run(~r/^(.+?)\s+<<(\w+)$/, trimmed) do
      [_, cmd, marker] -> {:heredoc_start, cmd, marker}
      nil -> {:command, trimmed}
    end
  end

  # Handle classification results
  defp handle_classification(:skip, _line, rest, acc, line_num) do
    parse_lines(rest, acc, :normal, line_num + 1)
  end

  defp handle_classification({:command, cmd}, _line, rest, acc, line_num) do
    parse_lines(rest, [{:command, cmd} | acc], :normal, line_num + 1)
  end

  defp handle_classification({:heredoc_start, cmd, marker}, _line, rest, acc, line_num) do
    parse_lines(rest, acc, {:in_heredoc, cmd, marker, [], line_num}, line_num + 1)
  end

  # Check if heredoc line is the closing marker
  defp check_heredoc_end(trimmed, marker) when trimmed == marker, do: :end_heredoc
  defp check_heredoc_end(_trimmed, _marker), do: :heredoc_content

  # Handle heredoc end marker
  defp handle_heredoc_line(:end_heredoc, _line, rest, acc, cmd, marker, lines, _start, line_num) do
    command = {:command_with_stdin, cmd, marker, Enum.reverse(lines)}
    parse_lines(rest, [command | acc], :normal, line_num + 1)
  end

  # Handle heredoc content line (preserve original whitespace)
  defp handle_heredoc_line(:heredoc_content, line, rest, acc, cmd, marker, lines, start, line_num) do
    parse_lines(rest, acc, {:in_heredoc, cmd, marker, [line | lines], start}, line_num + 1)
  end

  # Execute parsed commands

  defp handle_parse_result({:ok, commands}, settings, optimus) do
    Enum.each(commands, &execute_command(&1, settings, optimus))
    :ok
  end

  defp handle_parse_result({:error, {:unclosed_heredoc, marker, start_line}}, _settings, _optimus) do
    raise "Unclosed heredoc starting at line #{start_line}: expected '#{marker}' but reached end of file"
  end

  # Execute regular command
  defp execute_command({:command, cmd}, settings, optimus) do
    IO.puts("\nscript> #{cmd}")

    cmd
    |> then(&Repl.eval_for_redo({0, &1}, settings, optimus))
    |> Repl.print_result()
  end

  # Execute command with heredoc stdin
  defp execute_command({:command_with_stdin, cmd, marker, stdin_lines}, settings, optimus) do
    IO.puts("\nscript> #{cmd} <<#{marker}")
    Enum.each(stdin_lines, &IO.puts("  #{&1}"))
    IO.puts(marker)

    with_stdin_provider(stdin_lines, fn ->
      cmd
      |> then(&Repl.eval_for_redo({0, &1}, settings, optimus))
      |> Repl.print_result()
    end)
  end

  # Redirect stdin via group leader
  defp with_stdin_provider(lines, fun) do
    original_leader = Process.group_leader()
    {:ok, provider} = InputProvider.start_link(lines, original_leader)

    try do
      Process.group_leader(self(), provider)
      fun.()
    after
      Process.group_leader(self(), original_leader)
      GenServer.stop(provider)
    end
  end
end
