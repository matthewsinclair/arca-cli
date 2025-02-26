defmodule Arca.CLI do
  @moduledoc """
  Arca.CLI is a flexible command-line interface utility for Elixir projects.

  This module serves as the main entry point for the CLI application and provides:

  1. Command dispatcher and routing functionality
  2. Configuration and settings management
  3. Error handling and formatting
  4. Application lifecycle management

  The CLI follows a modular design with pluggable commands and configurators.
  Commands are registered through configurators, which are responsible for
  setting up the CLI environment and registering available commands.

  ## Architecture

  - Commands: Individual command implementations in `Arca.CLI.Command.*`
  - Configurators: Setup modules in `Arca.CLI.Configurator.*` 
  - History: Command history tracking in `Arca.CLI.History`
  - Utils: Utility functions in `Arca.CLI.Utils`

  ## Error Handling

  The application uses {:ok, result} and {:error, reason} tuples for error handling.
  """

  use Application
  require Logger
  require OK
  use OK.Pipe
  import Arca.CLI.Utils
  alias Arca.Config.Cfg
  alias Arca.CLI.Configurator.Coordinator

  @doc """
  Handle Application functionality to start the Arca.CLI subsystem.
  """
  @impl true
  def start(_type, _args) do
    # Logger.info("#{__MODULE__}.start: #{inspect(args)}")

    children = [
      {Arca.CLI.HistorySupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Arca.CLI]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Entry point for command line parsing.
  """
  def main(argv) do
    Application.put_env(:elixir, :ansi_enabled, true)
    unless length(argv) != 0, do: intro() |> put_lines

    settings = load_settings() |> with_default(%{})
    optimus = optimus_config()

    Optimus.parse(optimus, argv)
    |> handle_args(settings, optimus)
    |> filter_blank_lines
    |> put_lines
  end

  @doc """
  Provide an Optimus config to drive the CLI.
  """
  def optimus_config do
    configurators()
    |> Coordinator.setup()
  end

  @doc """
  Grab the list of Configurators specified in config to :arca_cli.
  """
  def configurators() do
    Application.fetch_env!(:arca_cli, :configurators)
  end

  @doc """
  Grab the list of Commands that have been specified in config to :arca_cli.
  """
  def commands() do
    configurators()
    |> Enum.flat_map(& &1.commands())
  end

  @doc """
  Return the command handler for the specfied command. Look in commands if provided, and if not, default to the list of commands provided by the commands() function.
  
  Supports both standard commands (e.g., `:about`) and dot notation commands (e.g., `:"sys.info"`).
  """
  def handler_for_command(cmd, commands \\ commands()) do
    command_string = Atom.to_string(cmd)
    
    # For dot notation, convert sys.info -> SysInfoCommand
    # For standard notation, convert sys -> SysCommand
    command_module_name = command_string
      |> String.split(".")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join("")
      |> Kernel.<>("Command")

    # Find the command handler module
    handler = commands
    |> Enum.find(fn module ->
      module_name_parts = Module.split(module)
      List.last(module_name_parts) == command_module_name
    end)
    
    case handler do
      nil -> nil
      module -> {:ok, cmd, module}
    end
  end

  @doc """
  Handle the command line arguments.
  """
  def handle_args(args, settings, optimus) do
    case args do
      {:ok, [subcmd], args} ->
        handle_subcommand(subcmd, args, settings, optimus)

      {:ok, msg} when is_binary(msg) ->
        msg

      {:ok, %Optimus.ParseResult{unknown: []}} ->
        # When called with no params, just show usage
        Optimus.Help.help(optimus, [], 80) |> Enum.drop(2)

      {:ok, %Optimus.ParseResult{unknown: errors}} ->
        # When called with an unknown param(s), show an error
        handle_error(["Unknown command:"] ++ errors)

      {:error, cmd, reason} ->
        handle_error(cmd, reason)

      {:error, reason} ->
        handle_error(reason)

      {:help, subcmd} ->
        # Optimus.Help.help puts intro() and contact() on the front of this, so drop it
        Optimus.Help.help(optimus, subcmd, 80) |> Enum.drop(2)

      :help ->
        # Optimus.Help.help puts intro() and contact() on the front of this, so drop it
        Optimus.Help.help(optimus, [], 80) |> Enum.drop(2)

      _other ->
        # Optimus.Help.help puts intro() and contact() on the front of this, so drop it
        Optimus.Help.help(optimus, [], 80) |> Enum.drop(2)
    end
  end

  @doc """
  Dispatch to the appropriate subcommand, if we can find one.

  ## Parameters
    - cmd: Command name (atom)
    - args: Command arguments
    - settings: Application settings
    - optimus: Optimus configuration
    
  ## Returns
    - Command result or error message
  """
  def handle_subcommand(cmd, args, settings, optimus) do
    # Logger.info("#{__MODULE__}.handle_subcommand: #{inspect(cmd)}, #{inspect(args)}")

    case handler_for_command(cmd) do
      nil ->
        handle_error(cmd, "unknown command: #{cmd}")

      {:ok, _cmd_atom, handler} ->
        try do
          handler.handle(args, settings, optimus)
        rescue
          e ->
            Logger.error("Error executing command #{cmd}: #{inspect(e)}")
            handle_error(cmd, "command execution failed: #{inspect(e)}")
        end
    end
  end

  @doc """
  Handle an error nicely and return a formatted error message.

  ## Parameters
    - cmd: Command name that caused the error (atom, string, or list)
    - reason: Error reason (any type)
    
  ## Returns
    - String containing formatted error message
  """
  # Handle atom command
  def handle_error(cmd, reason) when is_atom(cmd) do
    handle_error([Atom.to_string(cmd)], format_reason(reason))
  end

  # Handle command with list of reasons or single reason
  def handle_error(cmd, reason) when is_list(cmd) do
    ("error: " <> Enum.join(cmd, " ") <> ": " <> format_reason(reason))
    |> String.trim()
  end

  # Handle string command with any reason
  def handle_error(cmd, reason) when is_binary(cmd) do
    # Special case for "unknown command" errors with potential dot notation
    message = if reason =~ "unknown command" do
      similar_commands = similar_commands(cmd)
      
      # Handle namespaces more elegantly
      cond do
        !String.contains?(cmd, ".") && Enum.any?(similar_commands, &String.starts_with?(&1, "#{cmd}.")) ->
          namespace_commands = similar_commands
                              |> Enum.filter(&String.starts_with?(&1, "#{cmd}."))
                              |> Enum.sort()
          
          # This is a namespace prefix, show available commands in this namespace
          "#{cmd} is a command namespace. Available commands:\n#{Enum.join(namespace_commands, ", ")}\n" <>
          "Try '#{cmd}.<command>' to run a specific command in this namespace."
          
        true ->
          # Standard error with suggestions
          if Enum.empty?(similar_commands) do
            "error: #{cmd}: #{format_reason(reason)}"
          else
            namespaced_hint = if Enum.any?(similar_commands, &String.contains?(&1, ".")) do
              "\nHint: Commands can use dot notation for namespaces (e.g., 'sys.info', 'dev.deps')"
            else
              ""
            end
            
            "error: #{cmd}: #{format_reason(reason)}\nDid you mean one of these? #{Enum.join(similar_commands, ", ")}#{namespaced_hint}"
          end
      end
    else
      "error: #{cmd}: #{format_reason(reason)}"
    end
    
    message |> String.trim()
  end
  
  # Helper to find similar commands for better error messages
  defp similar_commands(cmd) do
    all_command_names = commands()
    |> Enum.map(fn module ->
      {cmd_atom, _opts} = apply(module, :config, []) |> List.first()
      Atom.to_string(cmd_atom)
    end)
    
    # First check if this might be a namespace reference
    namespace_matches = all_command_names
    |> Enum.filter(&String.starts_with?(&1, cmd <> "."))
    
    # Also look for commands that are similar
    similarity_matches = all_command_names
    |> Enum.filter(fn candidate -> 
      String.jaro_distance(cmd, candidate) > 0.7 || 
      (String.contains?(candidate, ".") && 
       String.jaro_distance(cmd, String.split(candidate, ".") |> List.last()) > 0.7)
    end)
    
    (namespace_matches ++ similarity_matches)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.take(5)  # Limit to reasonable number of suggestions
  end

  # Handle RuntimeError exception
  def handle_error(%RuntimeError{message: message}), do: handle_error(message)

  # Handle list of reasons without command
  def handle_error(reasons) when is_list(reasons) do
    ("error: " <> Enum.join(reasons, " "))
    |> String.trim()
  end

  # Handle string reason without command
  def handle_error(reason) when is_binary(reason) do
    "error: #{reason}"
    |> String.trim()
  end

  # Handle any other error type
  def handle_error(reason) do
    "error: #{inspect(reason)}"
    |> String.trim()
  end

  # Private helper to format error reasons consistently
  defp format_reason(reason) when is_list(reason), do: Enum.join(reason, " ")
  defp format_reason(reason) when is_binary(reason), do: reason
  defp format_reason(reason), do: inspect(reason)

  @doc """
  Load settings from JSON config file.

  ## Returns
    - Map with settings on success
    - Empty map on error, with a warning logged
  """
  def load_settings() do
    case Cfg.load() do
      {:ok, settings} ->
        settings

      {:error, reason} ->
        Logger.warning("Failed to load settings: #{inspect(reason)}")
        %{}
    end
  end

  @doc """
  Get a setting by its id (and with dot notation).

  ## Parameters
    - id: The setting identifier
    
  ## Returns
    - Setting value on success
    - {:error, reason} if setting couldn't be retrieved
  """
  def get_setting(id) do
    case Cfg.get(id) do
      {:ok, value} -> value
      {:error, reason} -> {:error, "Error getting setting: #{reason}"}
    end
  end

  @doc """
  Save settings to JSON config file.

  ## Parameters
    - new_settings: Map containing new settings to be merged with existing ones
    
  ## Returns
    - {:ok, updated_settings} on success
    - {:error, reason} on failure
  """
  def save_settings(new_settings) do
    with {:ok, current_settings} <- Cfg.load(),
         updated_settings = Map.merge(current_settings, new_settings),
         {:ok, _result} <- Cfg.put(:settings, updated_settings) do
      {:ok, updated_settings}
    else
      {:error, reason} ->
        Logger.warning("Failed to save settings: #{inspect(reason)}")
        {:error, "Failed to save settings: #{inspect(reason)}"}
    end
  end

  @doc """
  Print an about message
  """
  def intro(args \\ [], settings \\ nil)

  def intro(_args, _settings) do
    about() <> "\n" <> description() <> "\n" <> url() <> "\n" <> name() <> " " <> version()
  end

  # Accessors for string constants set via config
  def about do
    Application.fetch_env!(:arca_cli, :about)
  end

  def url do
    Application.fetch_env!(:arca_cli, :url)
  end

  def name do
    Application.fetch_env!(:arca_cli, :name)
  end

  def description do
    Application.fetch_env!(:arca_cli, :description)
  end

  def version do
    Application.fetch_env!(:arca_cli, :version)
  end

  def author do
    Application.fetch_env!(:arca_cli, :author)
  end

  def prompt_symbol do
    Application.fetch_env!(:arca_cli, :prompt_symbol)
  end
end
