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
    # Not sure what to do with args here?
    IO.gets(prompt)
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

    Optimus.parse(optimus, String.split(args))
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
