defmodule Arca.Cli do
  @moduledoc """
  Arca.Cli is a flexible command-line interface utility for Elixir projects.

  This module serves as the main entry point for the CLI application and provides:

  1. Command dispatcher and routing functionality
  2. Configuration and settings management
  3. Error handling and formatting
  4. Application lifecycle management

  The CLI follows a modular design with pluggable commands and configurators.
  Commands are registered through configurators, which are responsible for
  setting up the CLI environment and registering available commands.

  ## Architecture

  - Commands: Individual command implementations in `Arca.Cli.Command.*`
  - Configurators: Setup modules in `Arca.Cli.Configurator.*` 
  - History: Command history tracking in `Arca.Cli.History`
  - Utils: Utility functions in `Arca.Cli.Utils`

  ## Configuration

  Arca.Cli uses Arca.Config to manage configuration files. Configuration is automatically
  derived based on the application name:

  - Default config directory: `~/.arca/`
  - Default config filename: `arca_cli.json` (derived from the application name)

  These paths can be overridden with environment variables:
  - `ARCA_CONFIG_PATH`: Override the configuration directory
  - `ARCA_CONFIG_FILE`: Override the configuration filename

  ## Error Handling

  The application uses {:ok, result} and {:error, reason} tuples for error handling.
  """

  use Application
  require Logger
  require OK
  use OK.Pipe
  import Arca.Cli.Utils
  alias Arca.Cli.Configurator.Coordinator

  @doc """
  Handle Application functionality to start the Arca.Cli subsystem.
  """
  @impl true
  def start(_type, _args) do
    # Logger.info("#{__MODULE__}.start: #{inspect(args)}")

    children = [
      {Arca.Cli.HistorySupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Arca.Cli]
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

    # Pre-check for help flag to handle it before argument validation
    if has_help_flag?(argv) do
      case argv do
        ["--help"] ->
          # Top-level help
          generate_filtered_help(optimus)
          |> filter_blank_lines
          |> put_lines

        [cmd | rest] when rest == ["--help"] ->
          # Command-specific help
          handle_command_help(cmd, optimus)
          |> filter_blank_lines
          |> put_lines

        _ ->
          # Normal parse for more complex cases
          Optimus.parse(optimus, argv)
          |> handle_args(settings, optimus)
          |> filter_blank_lines
          |> put_lines
      end
    else
      # Normal command parsing flow
      Optimus.parse(optimus, argv)
      |> handle_args(settings, optimus)
      |> filter_blank_lines
      |> put_lines
    end
  end

  @doc """
  Check if the command line arguments contain a help flag
  """
  def has_help_flag?(argv) do
    "--help" in argv
  end

  @doc """
  Handle help for a specific command
  """
  def handle_command_help(cmd, optimus) do
    command_atom = String.to_atom(cmd)

    case handler_for_command(command_atom) do
      {:ok, _cmd_atom, _handler} ->
        # Found a valid command, show its help text
        help_lines = Optimus.Help.help(optimus, [command_atom], 80) |> Enum.drop(2)

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

      nil ->
        # Command not found
        ["error: unknown command: #{cmd}"]
    end
  end

  @doc """
  Provide an Optimus config to drive the CLI.
  """
  def optimus_config do
    # We need to include hidden commands in the config for execution
    # but help display will use commands(false) to filter them
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

  ## Parameters
    - include_hidden: Whether to include commands marked with hidden: true (default: true)
  """
  def commands(include_hidden \\ true) do
    cmds =
      configurators()
      |> Enum.flat_map(& &1.commands())

    if include_hidden do
      cmds
    else
      # Filter out hidden commands for display in help
      cmds
      |> Enum.reject(fn module ->
        {_cmd_atom, opts} = apply(module, :config, []) |> List.first()
        Keyword.get(opts, :hidden, false)
      end)
    end
  end

  @doc """
  Return the command handler for the specfied command. Look in commands if provided, and if not, default to the list of commands provided by the commands() function.

  Supports both standard commands (e.g., `:about`) and dot notation commands (e.g., `:"sys.info"`).
  """
  def handler_for_command(cmd, commands \\ commands()) do
    command_string = Atom.to_string(cmd)

    # For dot notation, convert sys.info -> SysInfoCommand
    # For standard notation, convert sys -> SysCommand
    command_module_name =
      command_string
      |> String.split(".")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join("")
      |> Kernel.<>("Command")

    # Find the command handler module
    handler =
      commands
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
        # Use helper function to generate filtered help text
        generate_filtered_help(optimus)

      {:ok, %Optimus.ParseResult{unknown: errors}} ->
        # When called with an unknown param(s), show an error
        handle_error(["Unknown command:"] ++ errors)

      {:error, cmd, reason} ->
        handle_error(cmd, reason)

      {:error, reason} ->
        handle_error(reason)

      {:help, subcmd} ->
        # Optimus.Help.help puts intro() and contact() on the front of this, so drop it
        help_lines = Optimus.Help.help(optimus, subcmd, 80) |> Enum.drop(2)

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

      :help ->
        # Use helper function to generate filtered help text
        generate_filtered_help(optimus)

      _other ->
        # Use helper function to generate filtered help text
        generate_filtered_help(optimus)
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
    message =
      if reason =~ "unknown command" do
        similar_commands = similar_commands(cmd)

        # Handle namespaces more elegantly
        cond do
          !String.contains?(cmd, ".") &&
              Enum.any?(similar_commands, &String.starts_with?(&1, "#{cmd}.")) ->
            namespace_commands =
              similar_commands
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
              namespaced_hint =
                if Enum.any?(similar_commands, &String.contains?(&1, ".")) do
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
    all_command_names =
      commands()
      |> Enum.map(fn module ->
        {cmd_atom, _opts} = apply(module, :config, []) |> List.first()
        Atom.to_string(cmd_atom)
      end)

    # First check if this might be a namespace reference
    namespace_matches =
      all_command_names
      |> Enum.filter(&String.starts_with?(&1, cmd <> "."))

    # Also look for commands that are similar
    similarity_matches =
      all_command_names
      |> Enum.filter(fn candidate ->
        String.jaro_distance(cmd, candidate) > 0.7 ||
          (String.contains?(candidate, ".") &&
             String.jaro_distance(cmd, String.split(candidate, ".") |> List.last()) > 0.7)
      end)

    (namespace_matches ++ similarity_matches)
    |> Enum.uniq()
    |> Enum.sort()
    # Limit to reasonable number of suggestions
    |> Enum.take(5)
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

  This function handles both the legacy and new configuration paths:
  1. Tries the new automatic path (arca_cli.json)
  2. Falls back to the previous hard-coded path (config.json) for backward compatibility

  ## Returns
    - Map with settings on success
    - Empty map on error, with a warning logged
  """
  def load_settings() do
    # Get standard config file path
    config_file = "~/.arca/arca_cli.json" |> Path.expand()
    legacy_path = "~/.arca/config.json" |> Path.expand()

    # Try reading from the standard path first
    case File.read(config_file) do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, settings} ->
            settings

          {:error, reason} ->
            Logger.warning("Failed to decode settings: #{inspect(reason)}")
            %{}
        end

      {:error, _} ->
        # Fall back to legacy path for backward compatibility
        case File.read(legacy_path) do
          {:ok, contents} ->
            case Jason.decode(contents) do
              {:ok, settings} ->
                Logger.info("Using legacy config path: #{legacy_path}")
                settings

              {:error, reason} ->
                Logger.warning("Failed to decode legacy settings: #{inspect(reason)}")
                %{}
            end

          {:error, _} ->
            # No configuration files found, return empty settings
            Logger.debug("No configuration found at standard or legacy paths")
            %{}
        end
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
    settings = load_settings()

    # Convert id to string for consistency
    key = to_string(id)

    case Map.fetch(settings, key) do
      {:ok, value} -> value
      :error -> {:error, "Setting not found: #{key}"}
    end
  end

  @doc """
  Save settings to JSON config file.

  Saves settings to the new automatically determined config file path.
  This helps migrate users from the old config path to the new one.

  ## Parameters
    - new_settings: Map containing new settings to be merged with existing ones
    
  ## Returns
    - {:ok, updated_settings} on success
    - {:error, reason} on failure
  """
  def save_settings(new_settings) do
    # Get config file path 
    config_file = "~/.arca/arca_cli.json" |> Path.expand()

    # Load existing settings (from either legacy or new path)
    current_settings = load_settings()

    # Merge with new settings
    updated_settings = Map.merge(current_settings, new_settings)

    # Ensure directory exists
    File.mkdir_p!(Path.dirname(config_file))

    # Direct file write for reliability
    case Jason.encode(updated_settings, pretty: true) do
      {:ok, json} ->
        case File.write(config_file, json) do
          :ok ->
            Logger.info("Settings saved to #{config_file}")
            {:ok, updated_settings}

          {:error, reason} ->
            Logger.warning("Failed to write config file: #{inspect(reason)}")
            {:error, "Failed to write config file: #{inspect(reason)}"}
        end

      {:error, reason} ->
        Logger.warning("Failed to encode settings: #{inspect(reason)}")
        {:error, "Failed to encode settings: #{inspect(reason)}"}
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

  @doc """
  Generate filtered help text that excludes commands with hidden: true
  """
  def generate_filtered_help(_optimus) do
    # Get commands and filter out hidden ones
    # Only non-hidden commands
    visible_commands = commands(false)

    # Format the header like Optimus.Help.help does, but use "cli" for the name
    # This provides consistency in the USAGE section
    header = [
      "USAGE:",
      "    cli ...",
      "    cli --version",
      "    cli --help",
      "    cli help subcommand",
      "",
      "SUBCOMMANDS:",
      ""
    ]

    # Format the command list
    command_list =
      visible_commands
      |> Enum.map(fn module ->
        {cmd_atom, opts} = apply(module, :config, []) |> List.first()
        name = Atom.to_string(cmd_atom)
        about = Keyword.get(opts, :about, "")
        padding = String.duplicate(" ", max(0, 20 - String.length(name)))
        "    #{name}#{padding}#{about}"
      end)

    # Combine header and command list
    header ++ command_list
  end

  def author do
    Application.fetch_env!(:arca_cli, :author)
  end

  def prompt_symbol do
    Application.fetch_env!(:arca_cli, :prompt_symbol)
  end
end
