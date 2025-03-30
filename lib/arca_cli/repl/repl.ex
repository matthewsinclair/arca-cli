defmodule Arca.Cli.Repl do
  @moduledoc """
  `Arca.Cli.Repl` provides a Read-Eval-Print Loop (REPL) for the Arca CLI application.

  This module manages the interactive command-line interface, allowing users to input commands,
  evaluate them, and see the results immediately. It supports various commands, including
  special cases like `quit`, `help`, and `history`.

  The REPL implementation follows Railway-Oriented Programming principles for error handling,
  with each operation returning either {:ok, result} or {:error, error_type, reason}.

  ## Usage

      iex> Arca.Cli.Repl.start([], Arca.Cli.optimus_config(), %{})
      {:ok, :quit}
  """

  alias Arca.Cli
  alias Arca.Cli.Callbacks
  alias Arca.Cli.History
  alias Arca.Cli.Utils
  require Logger

  @typedoc """
  Types of errors that can occur in REPL operations
  """
  @type error_type ::
          :input_error
          | :evaluation_error
          | :prompt_error
          | :output_error
          | :history_error
          | :tokenization_error

  @typedoc """
  Standard result tuple for operations that might fail
  """
  @type result(t) :: {:ok, t} | {:error, error_type(), String.t()}

  @doc """
  Kicks off the REPL loop.

  Sets up the REPL environment and starts the interactive loop.

  ## Parameters
    - args: Command line arguments
    - settings: Application settings
    - optimus: Command line parser configuration

  ## Returns
    - {:ok, :quit} when the REPL exits normally

  ## Examples

      iex> Arca.Cli.Repl.start([], Arca.Cli.optimus_config(), %{})
      {:ok, :quit}
  """
  @spec start([String.t()], map(), term()) :: {:ok, :quit}
  def start(args, settings, optimus) do
    # Set a process flag to indicate we're in REPL mode
    # This will be used by help generation to use prompt_symbol instead of app name
    Process.put(:is_repl_mode, true)

    with {:ok, intro} <- get_intro_text(args, settings),
         :ok <- display_intro(intro) do
      repl(args, settings, optimus)
    else
      {:error, _error_type, reason} ->
        Logger.error("Failed to start REPL: #{reason}")
        # Still attempt to start the REPL loop even if intro fails
        repl(args, settings, optimus)
    end
  end

  @doc """
  Get the introduction text for the REPL.

  ## Parameters
    - args: Command line arguments
    - settings: Application settings

  ## Returns
    - {:ok, intro_text} with formatted introduction text
    - {:error, error_type, reason} on failure
  """
  @spec get_intro_text([String.t()], map()) :: result(String.t())
  def get_intro_text(args, settings) do
    try do
      intro = Arca.Cli.intro(args, settings)
      {:ok, intro}
    rescue
      e ->
        {:error, :input_error, "Failed to generate intro text: #{inspect(e)}"}
    end
  end

  @doc """
  Display introduction text to the user.

  ## Parameters
    - intro_text: The text to display

  ## Returns
    - :ok on success
    - {:error, error_type, reason} on failure
  """
  @spec display_intro(String.t()) :: :ok | result(nil)
  def display_intro(intro_text) do
    try do
      Utils.put_lines(intro_text)
      :ok
    rescue
      e ->
        {:error, :output_error, "Failed to display intro: #{inspect(e)}"}
    end
  end

  # Loop through read/eval/print loop with Railway-Oriented error handling
  @spec repl([String.t()], map(), term()) :: {:ok, :quit}
  defp repl(args, settings, optimus) do
    with {:ok, input} <- read(args, settings, optimus),
         {:ok, result} <- eval(input, settings, optimus),
         {:ok, _} <- print_result(result) do
      # Handle different result types
      case result do
        {:ok, :quit} ->
          {:ok, :quit}

        {:ok, :nooutput} ->
          # Continue the REPL loop without printing anything
          repl(args, settings, optimus)

        _ ->
          # Continue the REPL loop
          repl(args, settings, optimus)
      end
    else
      # Input was EOF (user pressed Ctrl+D), treat as quit
      {:eof} ->
        {:ok, :quit}

      # Handle errors from any step in the pipeline
      {:error, error_type, reason} ->
        # Handle error and display to user
        error_message = format_error(error_type, reason)
        print_error(error_message)

        # Continue the REPL
        repl(args, settings, optimus)
    end
  end

  @doc """
  Format an error message based on error type and reason.

  ## Parameters
    - error_type: The type of error
    - reason: Error details

  ## Returns
    - Formatted error message string
  """
  @spec format_error(error_type(), String.t()) :: String.t()
  def format_error(:input_error, reason), do: "Input error: #{reason}"
  def format_error(:evaluation_error, reason), do: "Evaluation error: #{reason}"
  def format_error(:prompt_error, reason), do: "Prompt error: #{reason}"
  def format_error(:output_error, reason), do: "Output error: #{reason}"
  def format_error(:history_error, reason), do: "History error: #{reason}"
  def format_error(:tokenization_error, reason), do: "Tokenization error: #{reason}"
  def format_error(_unknown_error, reason), do: "Error: #{reason}"

  @doc """
  Print an error message to the user.

  ## Parameters
    - error_message: The error message to display

  ## Returns
    - :ok on success
  """
  @spec print_error(String.t()) :: :ok
  def print_error(error_message) do
    formatted = Cli.handle_error(error_message)
    print_result(formatted)
    :ok
  end

  # Parse REPL input into dispatchable params with error handling
  @spec read([String.t()], map(), term()) :: result(String.t() | [String.t()] | :eof)
  defp read(args, settings, optimus) do
    with {:ok, prompt} <- get_prompt(),
         {:ok, input} <- read_with_prompt(args, settings, optimus, prompt) do
      {:ok, input}
    end
  end

  @doc """
  Get the REPL prompt string.

  ## Returns
    - {:ok, prompt} with the formatted prompt string
    - {:error, error_type, reason} on failure
  """
  @spec get_prompt() :: result(String.t())
  def get_prompt() do
    try do
      prompt = repl_prompt()
      {:ok, prompt}
    rescue
      e ->
        {:error, :prompt_error, "Failed to generate prompt: #{inspect(e)}"}
    end
  end

  @spec read_with_prompt([String.t()], map(), term(), String.t()) ::
          result(String.t() | [String.t()]) | {:eof}
  defp read_with_prompt(_args, settings, optimus, prompt) do
    # Check if ExPrompt is available
    if Code.ensure_loaded?(ExPrompt) do
      # Read with enhanced prompt support
      case get_input_with_completion(prompt, settings, optimus) do
        {:ok, :eof} ->
          {:eof}

        {:ok, input} ->
          {:ok, input <> "\n"}

        {:error, error_type, reason} ->
          {:error, error_type, reason}
      end
    else
      # Fallback to standard IO.gets if ExPrompt is not available
      case get_standard_input(prompt) do
        {:ok, :eof} ->
          {:eof}

        {:ok, input} ->
          {:ok, input}

        {:error, error_type, reason} ->
          {:error, error_type, reason}
      end
    end
  end

  @doc """
  Get input using standard IO.gets function.

  ## Parameters
    - prompt: The prompt string to display

  ## Returns
    - {:ok, input} with the user input
    - {:ok, :eof} if end-of-file is reached
    - {:error, error_type, reason} on input error
  """
  @spec get_standard_input(String.t()) :: result(String.t() | :eof)
  def get_standard_input(prompt) do
    try do
      case IO.gets(prompt) do
        :eof ->
          {:ok, :eof}

        input ->
          {:ok, input}
      end
    rescue
      e ->
        {:error, :input_error, "Failed to read input: #{inspect(e)}"}
    end
  end

  @doc """
  Get input with command completion support.

  ## Parameters
    - prompt: The prompt string to display
    - settings: Application settings
    - optimus: Command line parser configuration

  ## Returns
    - {:ok, input} with the user input
    - {:ok, :eof} if end-of-file is reached
    - {:error, error_type, reason} on input error
  """
  @spec get_input_with_completion(String.t(), map(), term()) :: result(String.t() | :eof)
  def get_input_with_completion(prompt, settings \\ %{}, optimus \\ nil) do
    try do
      input = prompt_with_completion(prompt, settings, optimus)

      case input do
        :eof ->
          {:ok, :eof}

        input when is_binary(input) ->
          {:ok, input}
      end
    rescue
      e ->
        {:error, :input_error, "Failed to read input with completion: #{inspect(e)}"}
    end
  end

  # Custom prompt implementation with basic completion
  defp prompt_with_completion(prompt, settings \\ %{}, optimus \\ nil) do
    try do
      # Use simple input
      case IO.gets(prompt) do
        :eof ->
          :eof

        input ->
          trimmed = String.trim(input)

          # Store the raw input for debug tools
          Process.put(:last_repl_input, trimmed)

          handle_special_input(trimmed, prompt, settings, optimus)
      end
    rescue
      e ->
        Logger.error("Error with prompt: #{inspect(e)}")
        IO.puts("Error with prompt: #{inspect(e)}")
        IO.gets(prompt)
    end
  end

  @doc """
  Handle special input commands like "tab", "?", and namespace prefixes.

  ## Parameters
    - input: The user input string
    - prompt: The prompt string for recursion
    - settings: Application settings
    - optimus: Command line parser configuration

  ## Returns
    - The processed input or the result of recursive prompt calls
  """
  @spec handle_special_input(String.t(), String.t(), map(), term()) :: String.t() | :eof
  def handle_special_input(input, prompt, settings, optimus) do
    cond do
      input == "tab" ->
        # Show all commands if user explicitly types "tab"
        display_available_commands()
        prompt_with_completion(prompt)

      # Handle "?" as a single character (help shortcut)
      input == "?" ->
        # Use the central help generation function
        display_help(optimus)
        prompt_with_completion(prompt, settings, optimus)

      # Special namespace handling - if input is just a namespace prefix
      is_namespace_prefix?(input) ->
        display_namespace_commands(input)
        prompt_with_completion(prompt)

      true ->
        # No suggestions for complete command inputs - even with arguments
        # The REPL should not be making suggestions after the user has entered a command
        input
    end
  end

  @doc """
  Check if the input is a namespace prefix (like "sys" that could expand to "sys.command").

  ## Parameters
    - input: The user input string

  ## Returns
    - true if input is a namespace prefix
    - false otherwise
  """
  @spec is_namespace_prefix?(String.t()) :: boolean()
  def is_namespace_prefix?(input) do
    !String.contains?(input, ".") &&
      Enum.any?(available_commands(), &String.starts_with?(&1, "#{input}."))
  end

  @doc """
  Display all available commands in a formatted grid.

  ## Returns
    - :ok
  """
  @spec display_available_commands() :: :ok
  def display_available_commands() do
    suggestions = available_commands()
    IO.puts("\nAvailable commands:")

    suggestions
    |> Enum.sort()
    |> Enum.chunk_every(4)
    |> Enum.each(fn chunk ->
      IO.puts("  " <> Enum.join(chunk, "  "))
    end)

    :ok
  end

  @doc """
  Display help information.

  ## Parameters
    - optimus: Command line parser configuration

  ## Returns
    - :ok
  """
  @spec display_help(term()) :: :ok
  def display_help(optimus) do
    Cli.generate_filtered_help(optimus)
    |> Enum.join("\n")
    |> print()

    :ok
  end

  @doc """
  Display commands available in a namespace.

  ## Parameters
    - namespace: The namespace prefix (e.g., "sys")

  ## Returns
    - :ok
  """
  @spec display_namespace_commands(String.t()) :: :ok
  def display_namespace_commands(namespace) do
    namespace_commands =
      available_commands()
      |> Enum.filter(&String.starts_with?(&1, "#{namespace}."))
      |> Enum.sort()

    IO.puts("\n#{namespace} is a command namespace. Available commands:")
    IO.puts(Enum.join(namespace_commands, ", "))
    IO.puts("Try '#{namespace}.<command>' to run a specific command in this namespace.")

    :ok
  end

  # Evaluate input with proper error handling using Railway-Oriented Programming
  @spec eval(any(), map(), term()) :: result(any())
  defp eval(input, settings, optimus) do
    try do
      result = do_eval(input, settings, optimus)
      {:ok, result}
    rescue
      e ->
        {:error, :evaluation_error, "Failed to evaluate command: #{Exception.message(e)}"}
    end
  end

  # Specialized evaluation based on input type
  @spec do_eval(any(), map(), term()) :: any()

  # Handle 'repl' as a special case (do nothing)
  defp do_eval("repl\n", _settings, _optimus) do
    "The repl is already running."
  end

  # Handle 'q!' as a special case
  defp do_eval("q!\n", _settings, _optimus) do
    {:ok, :quit}
  end

  # Handle 'quit' as a special case
  defp do_eval("quit\n", _settings, _optimus) do
    {:ok, :quit}
  end

  # Handle '^d' as a special case
  defp do_eval(:eof, _settings, _optimus) do
    {:ok, :quit}
  end

  # Handle 'help' as a special case
  defp do_eval("help\n", _settings, optimus) do
    # Use our custom help generation function
    Cli.generate_filtered_help(optimus)
    |> Enum.join("\n")
  end

  # Evaluate params and dispatch to appropriate handler
  defp do_eval("\n", _settings, _optimus) do
    :ok
  end

  # Handle string input (from REPL)
  defp do_eval(args, settings, optimus) when is_binary(args) do
    # Add to history if appropriate
    update_history(args)

    # Split arguments while preserving quoted strings
    with {:ok, args_list} <- split_args(args) do
      Optimus.parse(optimus, args_list)
      |> Cli.handle_args(settings, optimus)
    else
      {:error, _error_type, reason} ->
        "Error: #{reason}"
    end
  end

  # Handle list input (from command line)
  defp do_eval(args, settings, optimus) when is_list(args) do
    # Add to history if appropriate
    update_history(args)

    Optimus.parse(optimus, args)
    |> Cli.handle_args(settings, optimus)
  end

  @doc """
  Update command history if the command should be stored.

  ## Parameters
    - cmd: The command to potentially add to history

  ## Returns
    - :ok
  """
  @spec update_history(String.t() | [String.t()]) :: :ok
  def update_history(cmd) do
    if should_push?(cmd) do
      try do
        History.push_cmd(cmd)
      rescue
        _ ->
          Logger.warning("Failed to update command history")
      end
    end

    :ok
  end

  @doc """
  Split command arguments while preserving quoted strings.

  ## Parameters
    - input: The command string to split

  ## Returns
    - {:ok, args_list} with the tokenized arguments
    - {:error, error_type, reason} on tokenization failure
  """
  @spec split_args(String.t()) :: result([String.t()])
  def split_args(input) do
    try do
      args_list = split_preserving_quotes(input)
      {:ok, args_list}
    rescue
      e ->
        {:error, :tokenization_error, "Failed to parse command: #{Exception.message(e)}"}
    end
  end

  # Split a string into arguments while preserving quoted segments
  @spec split_preserving_quotes(String.t()) :: [String.t()]
  defp split_preserving_quotes(input) do
    # Trim any leading/trailing whitespace
    trimmed = String.trim(input)

    # Special cases
    if trimmed == "" do
      []
    else
      # Process the input in stages to handle special cases
      # Stage 1: Tokenize without splitting by whitespace inside quotes
      result = tokenize_command_line(trimmed)

      # Stage 2: Process tokens to handle quoted values
      result
      |> Enum.map(&process_token/1)
    end
  end

  # Specialized tokenizer that preserves quoted segments
  @spec tokenize_command_line(String.t()) :: [String.t()]
  defp tokenize_command_line(input) do
    # First handle special case of dot notation commands
    if String.contains?(input, ".") && !String.contains?(input, "\"") do
      # For simple dot notation commands without quotes, use the existing approach
      String.split(input, ~r/\s+/, trim: true)
    else
      # Build tokens by scanning character by character
      {tokens, current_token, _in_quotes, _in_option_value} =
        input
        |> String.graphemes()
        |> Enum.reduce({[], "", false, false}, &process_char/2)

      # Add the final token if not empty
      tokens =
        if current_token != "" do
          tokens ++ [current_token]
        else
          tokens
        end

      tokens
    end
  end

  # Process each character in the input string
  @spec process_char(String.t(), {[String.t()], String.t(), boolean(), boolean()}) ::
          {[String.t()], String.t(), boolean(), boolean()}
  defp process_char(char, {tokens, current, in_quotes, in_option_value}) do
    cond do
      # Toggle quote state
      char == "\"" && !in_quotes ->
        {tokens, current <> char, true, in_option_value}

      char == "\"" && in_quotes ->
        {tokens, current <> char, false, in_option_value}

      # Handle whitespace
      char =~ ~r/\s/ && !in_quotes && !in_option_value ->
        if current == "" do
          {tokens, "", false, false}
        else
          {tokens ++ [current], "", false, false}
        end

      # Inside quotes or option value, keep building the current token
      in_quotes || in_option_value ->
        {tokens, current <> char, in_quotes, in_option_value}

      # Option value with equals sign
      char == "=" && current =~ ~r/^-{1,2}/ ->
        {tokens, current <> char, in_quotes, true}

      # Normal character, keep building the current token
      true ->
        {tokens, current <> char, in_quotes, in_option_value}
    end
  end

  # Process individual tokens to handle quoted values
  @spec process_token(String.t()) :: String.t()
  defp process_token(token) do
    cond do
      # Handle --option="value with spaces" format
      String.match?(token, ~r/^-{1,2}[^=]+=".+"$/) ->
        [name, value] = String.split(token, "=", parts: 2)
        # Remove quotes from the value
        unquoted_value =
          value
          |> String.trim_leading("\"")
          |> String.trim_trailing("\"")

        "#{name}=#{unquoted_value}"

      # Handle normal quoted strings
      String.starts_with?(token, "\"") && String.ends_with?(token, "\"") ->
        token
        |> String.trim_leading("\"")
        |> String.trim_trailing("\"")

      # Everything else passes through unchanged
      true ->
        token
    end
  end

  # Make sure not to push these commands to the command history
  @non_history_cmds ["history", "redo", "flush", "help"]

  @doc """
  Determines if a command should be pushed to the command history.

  ## Parameters
    - cmd: The command to check

  ## Returns
    - true if the command should be added to history
    - false if the command should not be added to history

  ## Examples

      iex> Arca.Cli.Repl.should_push?("history")
      false

      iex> Arca.Cli.Repl.should_push?("other_command")
      true
  """
  @spec should_push?(String.t() | [String.t()]) :: boolean()
  def should_push?(cmd) when is_binary(cmd) do
    Enum.filter(@non_history_cmds, fn item -> String.trim(cmd) =~ item end) |> length == 0
  end

  def should_push?(cmd) when is_list(cmd) do
    should_push?(Enum.join(cmd, ""))
  end

  @doc """
  Gets a list of available commands for autocompletion.
  Formats command names for display, including namespaced commands.
  Filters out commands with hidden: true in their configuration.

  ## Returns
    - List of available command strings

  ## Examples

      iex> Arca.Cli.Repl.available_commands()
      ["about", "history", "status", "dev.info", "sys.info", ...]
  """
  @spec available_commands() :: [String.t()]
  def available_commands do
    # Only include non-hidden commands
    Cli.commands(false)
    |> Enum.map(fn module ->
      {cmd_atom, _opts} = apply(module, :config, []) |> List.first()
      Atom.to_string(cmd_atom)
    end)
    |> Enum.sort()
  end

  @doc """
  Provides autocompletion suggestions for a partial command input.
  Supports both standard and dot notation commands.

  ## Parameters
    - partial: The partial command to complete

  ## Returns
    - List of matching command strings

  ## Examples

      iex> Arca.Cli.Repl.autocomplete("sy")
      ["sys", "sys.info", "sys.flush", "sys.cmd"]

      iex> Arca.Cli.Repl.autocomplete("dev.")
      ["dev.info", "dev.deps"]
  """
  @spec autocomplete(String.t()) :: [String.t()]
  def autocomplete(partial) do
    available_commands()
    |> Enum.filter(&String.starts_with?(&1, partial))
    |> Enum.sort()
    |> case do
      [] ->
        find_namespace_completions(partial)

      matches ->
        matches
    end
  end

  @doc """
  Find namespace-based completions when direct matches aren't found.

  ## Parameters
    - partial: The partial command to complete

  ## Returns
    - List of matching namespaces or commands
  """
  @spec find_namespace_completions(String.t()) :: [String.t()]
  def find_namespace_completions(partial) do
    if String.contains?(partial, ".") do
      # For "namespace." syntax, return all commands in that namespace
      namespace = String.split(partial, ".") |> List.first()

      available_commands()
      |> Enum.filter(&String.starts_with?(&1, namespace <> "."))
    else
      # Return namespaces that start with the partial command
      available_commands()
      |> Enum.filter(&String.starts_with?(&1, partial))
      |> Enum.map(fn cmd ->
        if String.contains?(cmd, ".") do
          String.split(cmd, ".") |> List.first()
        else
          cmd
        end
      end)
      |> Enum.uniq()
    end
  end

  @doc """
  Evaluates a command from the history for redo.

  ## Parameters
    - history_entry: The history entry to redo
    - settings: Application settings
    - optimus: Command line parser configuration

  ## Returns
    - The result of evaluating the command

  ## Examples

      iex> Arca.Cli.Repl.eval_for_redo({1, "about"}, Arca.Cli.optimus_config(), %{})
      "📦 Arca CLI..."
  """
  @spec eval_for_redo({integer(), String.t()}, map(), term()) :: any()
  def eval_for_redo({_history_id, history_cmd}, settings, optimus) when is_binary(history_cmd) do
    case eval(history_cmd, settings, optimus) do
      {:ok, result} -> result
      {:error, _error_type, reason} -> "Error redoing command: #{reason}"
    end
  end

  # Print result with proper error handling
  @doc """
  Handles the result of command evaluation, deciding whether to print output.

  ## Parameters
    - result: The command result to process
    
  ## Returns
    - {:ok, result} on success
    - {:error, error_type, reason} on failure
    
  ## Cases
    - For {:ok, :nooutput}, skips printing and returns the result as-is
    - For {:ok, :quit}, returns the result without printing
    - For other {:ok, _} or {:error, _, _} tuples, returns without printing
    - For all other values, prints the result and returns it
  """
  @spec print_result(any()) :: result(any())
  def print_result({:ok, :nooutput} = result), do: {:ok, result}
  def print_result({:ok, :quit} = result), do: {:ok, result}
  def print_result({:ok, _} = result), do: {:ok, result}
  def print_result({:error, _, _} = result), do: {:ok, result}

  def print_result(result) do
    try do
      printed = print(result)
      {:ok, printed}
    rescue
      e ->
        {:error, :output_error, "Failed to display output: #{Exception.message(e)}"}
    end
  end

  # Return tuples directly without printing them
  defp print(out) when is_tuple(out), do: out

  # Print using callbacks if available, otherwise fall back to default implementation
  defp print(out) do
    # Detect if this is a help output that should bypass formatter callbacks
    is_help_output = is_help_text?(out)

    cond do
      # Help output should bypass formatter to avoid display issues
      is_help_output ->
        print_help_output(out)

      # Also handle help tuples directly
      out == :help || (is_tuple(out) && tuple_size(out) == 2 && elem(out, 0) == :help) ->
        out

      # Normal formatter path for non-help output
      Code.ensure_loaded?(Callbacks) && Callbacks.has_callbacks?(:format_output) ->
        print_formatted_output(out)

      # Fallback to default implementation
      true ->
        Utils.print(out)
    end
  end

  @doc """
  Print help output, handling both string and list formats.

  ## Parameters
    - out: The help text to display

  ## Returns
    - The input, passed through after printing
  """
  @spec print_help_output(String.t() | [String.t()]) :: any()
  def print_help_output(out) do
    if is_list(out) do
      Enum.join(out, "\n") |> IO.puts()
    else
      IO.puts(out)
    end

    out
  end

  @doc """
  Print output using the formatter callbacks.

  ## Parameters
    - out: The output to format and display

  ## Returns
    - The input, passed through after printing
  """
  @spec print_formatted_output(any()) :: any()
  def print_formatted_output(out) do
    # Get formatted output from callbacks
    formatted = Callbacks.execute(:format_output, out)

    # Only print if it's not empty
    if formatted && formatted != "" do
      IO.puts(formatted)
    end

    out
  end

  @doc """
  Determine if the given output is help text that should bypass formatter callbacks.

  ## Parameters
    - out: The output to check

  ## Returns
    - true if the output is help text
    - false otherwise
  """
  @spec is_help_text?(any()) :: boolean()
  def is_help_text?(out) do
    cond do
      # Check for "USAGE:" in string content
      is_binary(out) && String.contains?(out, "USAGE:") -> true
      # Check for "USAGE:" in any element of list
      is_list(out) && Enum.any?(out, &(is_binary(&1) && String.contains?(&1, "USAGE:"))) -> true
      # Not help text
      true -> false
    end
  end

  # Provide the REPL's prompt
  @spec repl_prompt() :: String.t()
  defp repl_prompt() do
    "\n#{Arca.Cli.prompt_symbol()} #{History.hlen()} > "
  end
end
