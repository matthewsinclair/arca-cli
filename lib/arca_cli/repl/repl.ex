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
        :eof -> :eof
        _ ->
          trimmed = String.trim(input)
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
              namespace_commands = available_commands()
                                |> Enum.filter(&String.starts_with?(&1, "#{trimmed}."))
                                |> Enum.sort()
              
              IO.puts("\n#{trimmed} is a command namespace. Available commands:")
              IO.puts(Enum.join(namespace_commands, ", "))
              IO.puts("Try '#{trimmed}.<command>' to run a specific command in this namespace.")
              prompt_with_completion(prompt)
              
            true ->
              # Check if this is a partial command and suggest completions
              # We'll only show suggestions if Tab completion is not available
              # Check if we're running under rlwrap
              if !System.get_env("RLWRAP_COMMAND_PID") do
                suggestions = autocomplete(trimmed)
                if length(suggestions) > 0 && length(suggestions) < 10 && String.length(trimmed) > 0 do
                  IO.puts("\nSuggestions: #{Enum.join(suggestions, ", ")}")
                end
              end
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

  defp eval(args, settings, optimus) when is_binary(args) do
    should_push?(args) && History.push_cmd(args)

    # Special handling for dot notation commands
    args_list = if String.contains?(args, ".") do
      # For dot notation commands, we want to preserve the dots
      # Split by spaces, but keep the dot notation intact
      args
      |> String.trim()
      |> String.split(~r/\s+/, trim: true)
    else
      args |> String.trim() |> String.split()
    end
    
    Optimus.parse(optimus, args_list)
    |> Cli.handle_args(settings, optimus)
  end

  defp eval(args, settings, optimus) when is_list(args) do
    should_push?(args) && History.push_cmd(args)

    Optimus.parse(optimus, args)
    |> Cli.handle_args(settings, optimus)
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
    Cli.commands(false) # Only include non-hidden commands
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
      matches -> matches
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

  # Ignore tuples when printing and return what was sent in (a bit like tee)
  defp print(out) when is_tuple(out), do: out

  # Default print to ANSI and return what was printed (a bit like tee)
  defp print(out), do: Utils.print(out)

  # Provide the REPL's prompt
  defp repl_prompt() do
    "\n#{Arca.Cli.prompt_symbol()} #{History.hlen()} > "
  end
end
