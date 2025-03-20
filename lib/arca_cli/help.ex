defmodule Arca.Cli.Help do
  @moduledoc """
  Centralized help system for Arca.Cli.

  This module provides a unified interface for handling help requests across
  all command scenarios. It's designed to be used at the pre-execution stage
  to determine if help should be shown instead of executing a command.

  ## Help Scenarios

  This module handles three main help scenarios:

  1. Command invoked without parameters: `cli cmd`
     - This shows help if the command has `show_help_on_empty: true`
     - Commands requiring arguments should set this to true
     - Commands that work without args should set this to false
     
  2. Command invoked with `--help` flag: `cli cmd --help`
     - Always shows help regardless of command configuration
     
  3. Command invoked with help prefix: `cli help cmd`
     - Always shows help regardless of command configuration

  ## Integration with BaseCommand

  Commands that use `Arca.Cli.Command.BaseCommand` can simply set the 
  `show_help_on_empty` configuration parameter to control when help is shown:

  ```elixir
  defmodule MyApp.Commands.QueryCommand do
    use Arca.Cli.Command.BaseCommand
    
    config :query,
      name: "query",
      about: "Query data from the system",
      show_help_on_empty: true  # Show help when invoked without args
      
    @impl true
    def handle(args, settings, optimus) do
      # Just implement the command logic - help is handled automatically
      # ...
    end
  end
  ```
  """

  require Logger
  alias Arca.Cli.Callbacks

  @doc """
  Determines if help should be shown for a command with the given arguments.

  Checks three conditions:
  1. If the command is invoked with --help flag
  2. If the command is configured to show help on empty arguments
  3. If the command requires arguments but none were provided

  ## Parameters
    - cmd: Command name or atom
    - args: Command arguments from Optimus.parse
    - handler: (Optional) Command handler module

  ## Returns
    - true if help should be displayed, false otherwise
  """
  def should_show_help?(cmd, args, handler \\ nil) do
    cmd_atom = if is_binary(cmd), do: String.to_atom(cmd), else: cmd
    handler = handler || get_handler_for_command(cmd_atom)

    has_help_flag?(args) ||
      (handler && is_empty_command_args?(args) && show_help_on_empty?(handler))
  end

  @doc """
  Generates and displays help for a command.

  ## Parameters
    - cmd: Command name or atom
    - args: Command arguments
    - optimus: Optimus configuration

  ## Returns
    - Formatted help text
  """
  def show(cmd, _args, optimus) do
    cmd
    |> to_atom()
    |> generate_help(optimus)
    |> format_help()
  end

  @doc """
  Checks if a command is configured to show help when invoked with empty arguments.

  ## Parameters
    - handler: Command handler module

  ## Returns
    - true if the command should show help on empty, false otherwise
  """
  def show_help_on_empty?(handler) do
    try do
      handler
      |> apply(:config, [])
      |> List.first()
      |> elem(1)
      |> Keyword.get(:show_help_on_empty, false)
    rescue
      _ -> false
    end
  end

  @doc """
  Checks if arguments contain the --help flag.

  ## Parameters
    - args: Command arguments

  ## Returns
    - true if --help is present, false otherwise
  """
  def has_help_flag?(args) do
    cond do
      is_list(args) ->
        "--help" in args

      is_map(args) && Map.has_key?(args, :flags) ->
        args |> Map.get(:flags, %{}) |> Map.get(:help, false)

      true ->
        false
    end
  end

  @doc """
  Checks if command arguments are empty.

  ## Parameters
    - args: Command arguments from Optimus.parse

  ## Returns
    - true if arguments are empty, false otherwise
  """
  def is_empty_command_args?(args) do
    case args do
      %{} = map when map_size(map) == 0 ->
        true

      %{metadata: _} = map when map_size(map) == 1 ->
        true

      %Optimus.ParseResult{args: args, flags: flags, options: options}
      when args == %{} and flags == %{} and options == %{} ->
        true

      ["--help"] ->
        true

      _ ->
        false
    end
  end

  # Private functions

  defp to_atom(cmd) when is_atom(cmd), do: cmd
  defp to_atom(cmd) when is_binary(cmd), do: String.to_atom(cmd)

  defp get_handler_for_command(cmd) do
    case Arca.Cli.handler_for_command(cmd) do
      {:ok, _cmd_atom, handler} -> handler
      _ -> nil
    end
  end

  defp generate_help(cmd, optimus) do
    help_lines =
      optimus
      |> Optimus.Help.help([cmd], 80)
      |> Enum.drop(2)

    # Always replace the app name with "cli" in USAGE line for consistency
    help_lines
    |> Enum.map(fn line ->
      if String.starts_with?(line, "    #{optimus.name}") do
        # Extract the part after the app name (command and args)
        app_name_len = String.length(optimus.name)
        line_len = String.length(line)

        remaining =
          if line_len > app_name_len + 4 do
            String.slice(line, (app_name_len + 4)..(line_len - 1))
          else
            ""
          end

        # Replace app name with "cli"
        "    cli#{remaining}"
      else
        line
      end
    end)
  end

  defp format_help(help_text) do
    if Callbacks.has_callbacks?(:format_help) do
      Callbacks.execute(:format_help, help_text)
    else
      help_text
    end
  end
end
