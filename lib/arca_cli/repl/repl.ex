defmodule Arca.CLI.Repl do
  @moduledoc """
  `Arca.CLI.Repl` provides a Read-Eval-Print Loop (REPL) for the Arca CLI application.

  This module manages the interactive command-line interface, allowing users to input commands,
  evaluate them, and see the results immediately. It supports various commands, including
  special cases like `quit`, `help`, and `history`.

  ## Usage

      iex> Arca.CLI.Repl.start([], Arca.CLI.optimus_config(), %{})
      {:ok, :quit}
  """

  alias Arca.CLI
  alias Arca.CLI.History
  alias Arca.CLI.Utils
  require Logger

  @doc """
  Kicks off the REPL loop.

  ## Examples

      iex> Arca.CLI.Repl.start([], Arca.CLI.optimus_config(), %{})
      {:ok, :quit}

  """
  def start(args, settings, optimus) do
    Arca.CLI.intro(args, settings) |> Utils.put_lines()
    repl(args, settings, optimus)
  end

  # Loop thru read/eval/print loop.
  defp repl(args, settings, optimus) do
    result =
      args
      |> read()
      |> eval(settings, optimus)
      |> print()

    case result do
      {:ok, :quit} ->
        {:ok, :quit}

      {:error, e} ->
        CLI.handle_error(e) |> print()
        repl(args, settings, optimus)

      _result ->
        repl(args, settings, optimus)
    end
  end

  # Parse REPL input into dispatchable params
  defp read(_args, prompt \\ repl_prompt()) do
    # Check if ExPrompt is available
    if Code.ensure_loaded?(ExPrompt) do
      # Read with enhanced prompt support
      # ExPrompt doesn't have a built-in completion functionality, so we'll enhance the basic prompt
      input = prompt_with_completion(prompt)
      
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
  defp prompt_with_completion(prompt) do
    try do
      # Display available commands hint
      cmd_count = available_commands() |> length()
      IO.puts("#{IO.ANSI.yellow()}Hint: #{cmd_count} commands available. Type a partial command and press Tab to see suggestions.#{IO.ANSI.reset()}")
      
      # Use simple input for now
      input = IO.gets(prompt)
      
      case input do
        :eof -> :eof
        _ ->
          trimmed = String.trim(input)
          cond do
            trimmed == "tab" || trimmed == "?" ->
              # Show all commands if user explicitly types "tab" or "?"
              suggestions = available_commands()
              IO.puts("\nAvailable commands:")
              suggestions
              |> Enum.sort()
              |> Enum.chunk_every(4)
              |> Enum.each(fn chunk -> 
                IO.puts("  " <> Enum.join(chunk, "  "))
              end)
              prompt_with_completion(prompt)
              
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
              suggestions = autocomplete(trimmed)
              if length(suggestions) > 0 && length(suggestions) < 10 && String.length(trimmed) > 0 do
                IO.puts("\nSuggestions: #{Enum.join(suggestions, ", ")}")
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
  defp eval("help\n", settings, optimus) do
    eval(["--help"], settings, optimus)
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
    |> CLI.handle_args(settings, optimus)
  end

  defp eval(args, settings, optimus) when is_list(args) do
    should_push?(args) && History.push_cmd(args)

    Optimus.parse(optimus, args)
    |> CLI.handle_args(settings, optimus)
  end

  # Make sure not to push these commands to the command history
  @non_history_cmds ["history", "redo", "flush", "help"]

  @doc """
  Determines if a command should be pushed to the command history.

  ## Examples

      iex> Arca.CLI.Repl.should_push?("history")
      false

      iex> Arca.CLI.Repl.should_push?("other_command")
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
  
  ## Examples
  
      iex> Arca.CLI.Repl.available_commands()
      ["about", "history", "status", "dev.info", "sys.info", ...]
  """
  def available_commands do
    CLI.commands()
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
  
      iex> Arca.CLI.Repl.autocomplete("sy")
      ["sys", "sys.info", "sys.flush", "sys.cmd"]
      
      iex> Arca.CLI.Repl.autocomplete("dev.")
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

      iex> Arca.CLI.Repl.eval_for_redo({1, "about"}, Arca.CLI.optimus_config(), %{})
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
    "\n#{Arca.CLI.prompt_symbol()} #{History.hlen()} > "
  end
end
