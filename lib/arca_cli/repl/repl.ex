defmodule Arca.Cli.Repl do
  @moduledoc """
  `Arca.Cli.Repl` provides a Read-Eval-Print Loop (REPL) for the Arca CLI application.

  This module manages the interactive command-line interface, allowing users to input commands,
  evaluate them, and see the results immediately. It supports various commands, including
  special cases like `quit`, `help`, and `history`.

  ## Usage

      iex> Arca.Cli.Repl.start([], Arca.Cli.optimus_config(), %{})
      {:ok, :quit}
  """

  alias Arca.Cli
  alias Arca.Cli.Callbacks
  alias Arca.Cli.History
  alias Arca.Cli.Utils
  require Logger

  @doc """
  Kicks off the REPL loop.

  ## Examples

      iex> Arca.Cli.Repl.start([], Arca.Cli.optimus_config(), %{})
      {:ok, :quit}

  """
  def start(args, settings, optimus) do
    # Set a process flag to indicate we're in REPL mode
    # This will be used by help generation to use prompt_symbol instead of app name
    Process.put(:is_repl_mode, true)

    Arca.Cli.intro(args, settings) |> Utils.put_lines()
    repl(args, settings, optimus)
  end

  # Loop thru read/eval/print loop.
  defp repl(args, settings, optimus) do
    result =
      args
      |> read(settings, optimus)
      |> eval(settings, optimus)
      |> print()

    case result do
      {:ok, :quit} ->
        {:ok, :quit}

      {:error, e} ->
        Cli.handle_error(e) |> print()
        repl(args, settings, optimus)

      _result ->
        repl(args, settings, optimus)
    end
  end

  # Parse REPL input into dispatchable params
  defp read(args, settings, optimus) do
    read_with_prompt(args, settings, optimus, repl_prompt())
  end

  defp read_with_prompt(_args, settings, optimus, prompt) do
    # Check if ExPrompt is available
    if Code.ensure_loaded?(ExPrompt) do
      # Read with enhanced prompt support
      # ExPrompt doesn't have a built-in completion functionality, so we'll enhance the basic prompt
      input = prompt_with_completion(prompt, settings, optimus)

      if input == :eof do
        :eof
      else
        input <> "\n"
      end
    else
      # Fallback to standard IO.gets if ExPrompt is not available
      IO.gets(prompt)
    end
  end

  # Custom prompt implementation with basic completion
  defp prompt_with_completion(prompt, settings \\ %{}, optimus \\ nil) do
    try do
      # Use simple input 
      input = IO.gets(prompt)

      case input do
        :eof ->
          :eof

        _ ->
          trimmed = String.trim(input)

          # Store the raw input for debug tools
          Process.put(:last_repl_input, trimmed)

          cond do
            trimmed == "tab" ->
              # Show all commands if user explicitly types "tab"
              suggestions = available_commands()
              IO.puts("\nAvailable commands:")

              suggestions
              |> Enum.sort()
              |> Enum.chunk_every(4)
              |> Enum.each(fn chunk ->
                IO.puts("  " <> Enum.join(chunk, "  "))
              end)

              prompt_with_completion(prompt)

            # Handle "?" as a single character (help shortcut)  
            trimmed == "?" ->
              # Use the central help generation function
              Cli.generate_filtered_help(optimus)
              |> Enum.join("\n")
              |> print()

              prompt_with_completion(prompt, settings, optimus)

            # Special namespace handling - if input is just a namespace prefix
            !String.contains?(trimmed, ".") &&
                Enum.any?(available_commands(), &String.starts_with?(&1, "#{trimmed}.")) ->
              namespace_commands =
                available_commands()
                |> Enum.filter(&String.starts_with?(&1, "#{trimmed}."))
                |> Enum.sort()

              IO.puts("\n#{trimmed} is a command namespace. Available commands:")
              IO.puts(Enum.join(namespace_commands, ", "))
              IO.puts("Try '#{trimmed}.<command>' to run a specific command in this namespace.")
              prompt_with_completion(prompt)

            true ->
              # No suggestions for complete command inputs - even with arguments
              # The REPL should not be making suggestions after the user has entered a command
              trimmed
          end
      end
    rescue
      e ->
        IO.puts("Error with prompt: #{inspect(e)}")
        IO.gets(prompt)
    end
  end

  # Handle 'repl' as a special case (do nothing)
  defp eval("repl\n", _settings, _optimus) do
    "The repl is already running."
  end

  # Handle 'q!' as a special case
  defp eval("q!\n", _settings, _optimus) do
    {:ok, :quit}
  end

  # Handle 'quit' as a special case
  defp eval("quit\n", _settings, _optimus) do
    {:ok, :quit}
  end

  # Handle '^d' as a special case
  defp eval(:eof, _settings, _optimus) do
    {:ok, :quit}
  end

  # Handle 'help' as a special case
  defp eval("help\n", _settings, optimus) do
    # Use our custom help generation function
    Cli.generate_filtered_help(optimus)
    |> Enum.join("\n")
  end

  # Evaluate params and dispatch to appropriate handler
  defp eval("\n", _settings, _optimus) do
    :ok
  end

  # Handle string input (from REPL)
  defp eval(args, settings, optimus) when is_binary(args) do
    should_push?(args) && History.push_cmd(args)

    # Split arguments while preserving quoted strings
    args_list = split_preserving_quotes(args)

    Optimus.parse(optimus, args_list)
    |> Cli.handle_args(settings, optimus)
  end

  # Handle list input (from command line)
  defp eval(args, settings, optimus) when is_list(args) do
    should_push?(args) && History.push_cmd(args)

    Optimus.parse(optimus, args)
    |> Cli.handle_args(settings, optimus)
  end

  # Split a string into arguments while preserving quoted segments
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

  ## Examples

      iex> Arca.Cli.Repl.should_push?("history")
      false

      iex> Arca.Cli.Repl.should_push?("other_command")
      true

  """
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

  ## Examples

      iex> Arca.Cli.Repl.available_commands()
      ["about", "history", "status", "dev.info", "sys.info", ...]
  """
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

  ## Examples

      iex> Arca.Cli.Repl.autocomplete("sy")
      ["sys", "sys.info", "sys.flush", "sys.cmd"]
      
      iex> Arca.Cli.Repl.autocomplete("dev.")
      ["dev.info", "dev.deps"]
  """
  def autocomplete(partial) do
    available_commands()
    |> Enum.filter(&String.starts_with?(&1, partial))
    |> Enum.sort()
    |> case do
      [] ->
        # If no direct matches, try finding namespace matches
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

      matches ->
        matches
    end
  end

  @doc """
  Evaluates a command from the history for redo.

  ## Examples

      iex> Arca.Cli.Repl.eval_for_redo({1, "about"}, Arca.Cli.optimus_config(), %{})
      "📦 Arca CLI..."

  """
  def eval_for_redo({_history_id, history_cmd}, settings, optimus) when is_binary(history_cmd) do
    eval(history_cmd, settings, optimus)
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
        if is_list(out) do
          Enum.join(out, "\n") |> IO.puts()
        else
          IO.puts(out)
        end
        out
      
      # Also handle help tuples directly
      out == :help || (is_tuple(out) && tuple_size(out) == 2 && elem(out, 0) == :help) ->
        out
      
      # Normal formatter path for non-help output
      Code.ensure_loaded?(Callbacks) && Callbacks.has_callbacks?(:format_output) ->
        # Get formatted output from callbacks
        formatted = Callbacks.execute(:format_output, out)

        # Only print if it's not empty
        if formatted && formatted != "" do
          IO.puts(formatted)
        end

        out
        
      # Fallback to default implementation
      true -> 
        Utils.print(out)
    end
  end
  
  @doc """
  Determine if the given output is help text that should bypass formatter callbacks.
  """
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
  defp repl_prompt() do
    "\n#{Arca.Cli.prompt_symbol()} #{History.hlen()} > "
  end
end
