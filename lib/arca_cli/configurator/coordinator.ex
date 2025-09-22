defmodule Arca.Cli.Configurator.Coordinator do
  @moduledoc """
  The `Arca.Cli.Configurator.Coordinator` is responsible for coordinating all of the configuration 
  necessary to get an Arca.Cli up and running.

  This module provides functions to:

  1. Set up CLI configuration using one or more configurator modules
  2. Merge configurations from multiple sources
  3. Detect and handle duplicate command and configurator definitions
  4. Generate the final Optimus configuration

  The coordinator follows a functional approach with Railway-Oriented Programming patterns for
  error handling and data transformation pipelines.
  """

  alias Arca.Cli.Configurator.DftConfigurator
  require Logger

  @typedoc """
  Types of errors that can occur in the Coordinator module.
  """
  @type error_type ::
          :invalid_configurator
          | :duplicate_configurator
          | :duplicate_command_name
          | :command_config_error
          | :configurator_setup_error

  @typedoc """
  Standard result tuple for operations that might fail.
  """
  @type result(t) :: {:ok, t} | {:error, error_type(), term()}

  @typedoc """
  Configuration map used in the setup process.
  """
  @type config_map :: %{optional(atom()) => any()}

  @typedoc """
  Map of command names to their configurator modules.
  """
  @type name_map :: %{optional(atom()) => [module()]}

  @doc """
  Coordinate setup of the CLI. 

  If no configuration is passed in, defaults to `Arca.Cli.Configurator.DftConfigurator`.
  Accepts either a single module or a list of modules that implement 
  the `Arca.Cli.Configurator.ConfiguratorBehaviour` protocol.

  ## Parameters
    - cfg8r: A configurator module or list of configurator modules
    
  ## Returns
    - Optimus configuration
  """
  @spec setup(module() | [module()]) :: Optimus.t()
  def setup(cfg8r \\ DftConfigurator)

  def setup(cfg8r) when is_atom(cfg8r) do
    cfg8r.setup()
  end

  def setup(cfg8r_list) when is_list(cfg8r_list) do
    with {:ok, unique_cfg8rs} <- identify_unique_configurators(cfg8r_list),
         {:ok, {combined_config, subcommand_names}} <- combine_configurator_data(unique_cfg8rs),
         :ok <- check_for_duplicated_commands(subcommand_names),
         {:ok, final_config} <- create_final_config(combined_config, unique_cfg8rs) do
      # Add global options once at the coordinator level
      final_config_with_options = add_global_cli_options(final_config)

      # Create the Optimus configuration
      Optimus.new!(final_config_with_options)
    else
      # Fallback to ensure we always return an Optimus configuration even if errors occurred
      {:error, _error_type, reason} ->
        Logger.error("Error during configurator setup: #{inspect(reason)}")
        DftConfigurator.setup()
    end
  end

  @doc """
  Identifies unique configurators and logs warnings about duplicates.

  ## Parameters
    - cfg8r_list: List of configurator modules
    
  ## Returns
    - {:ok, unique_configurators} with deduplicated list on success
    - {:error, error_type, reason} on failure
  """
  @spec identify_unique_configurators([module()]) :: result([module()])
  def identify_unique_configurators(cfg8r_list) do
    {unique_cfg8rs, duplicate_cfg8rs} =
      cfg8r_list
      |> Enum.group_by(& &1)
      |> Enum.split_with(fn {_key, value} -> length(value) == 1 end)

    # Log warnings about duplicates
    if duplicate_cfg8rs != [] do
      duplicated_modules = duplicate_cfg8rs |> Enum.map(fn {key, _value} -> key end)
      Logger.warning("Duplicate configurators found and rejected: #{inspect(duplicated_modules)}")
    end

    # Extract the unique configurators
    unique_cfg8r_list = unique_cfg8rs |> Enum.map(fn {key, _value} -> key end)
    {:ok, unique_cfg8r_list}
  end

  @doc """
  Combines configuration data from multiple configurators.

  ## Parameters
    - configurators: List of unique configurator modules
    
  ## Returns
    - {:ok, {combined_config, subcommand_names}} with merged configuration on success
    - {:error, error_type, reason} on failure
  """
  @spec combine_configurator_data([module()]) :: result({config_map(), name_map()})
  def combine_configurator_data(configurators) do
    result =
      Enum.reduce_while(configurators, {:ok, {%{}, %{}}}, fn cfg8r, {:ok, {acc, name_acc}} ->
        with {:ok, cfg8r_config} <- get_configurator_config(cfg8r),
             {:ok, cfg8r_commands} <- get_configurator_commands(cfg8r),
             {:ok, merged_config} <- merge_configs(acc, cfg8r_config),
             {:ok, updated_names} <- update_command_names(name_acc, cfg8r_commands, cfg8r) do
          {:cont, {:ok, {merged_config, updated_names}}}
        else
          {:error, error_type, reason} ->
            {:halt, {:error, error_type, reason}}
        end
      end)

    result
  end

  @doc """
  Gets the configuration from a configurator module.

  ## Parameters
    - configurator: A configurator module
    
  ## Returns
    - {:ok, config} with the configurator's config on success
    - {:error, error_type, reason} on failure
  """
  @spec get_configurator_config(module()) :: result(config_map())
  def get_configurator_config(configurator) do
    try do
      config = configurator.create_base_config() |> Enum.into(%{})
      {:ok, config}
    rescue
      error ->
        Logger.error(
          "Error getting configuration from #{inspect(configurator)}: #{inspect(error)}"
        )

        {:error, :configurator_setup_error,
         "Failed to get configuration from #{inspect(configurator)}"}
    end
  end

  @doc """
  Gets the commands from a configurator module.

  ## Parameters
    - configurator: A configurator module
    
  ## Returns
    - {:ok, commands} with the configurator's commands on success
    - {:error, error_type, reason} on failure
  """
  @spec get_configurator_commands(module()) :: result([module()])
  def get_configurator_commands(configurator) do
    try do
      commands = configurator.commands()
      {:ok, commands}
    rescue
      error ->
        Logger.error("Error getting commands from #{inspect(configurator)}: #{inspect(error)}")

        {:error, :configurator_setup_error,
         "Failed to get commands from #{inspect(configurator)}"}
    end
  end

  @doc """
  Merges two configuration maps, handling lists specially.

  ## Parameters
    - config1: First configuration map
    - config2: Second configuration map to merge into the first
    
  ## Returns
    - {:ok, merged_config} with the merged configuration
  """
  @spec merge_configs(config_map(), config_map()) :: result(config_map())
  def merge_configs(config1, config2) do
    merged_config =
      Map.merge(config1, config2, fn _key, v1, v2 ->
        case {v1, v2} do
          {list1, list2} when is_list(list1) and is_list(list2) -> list1 ++ list2
          {_, v2} -> v2
        end
      end)

    {:ok, merged_config}
  end

  @doc """
  Updates the command name mapping with new commands from a configurator.

  ## Parameters
    - name_acc: Accumulated command name mapping
    - commands: List of command modules
    - configurator: The configurator module these commands come from
    
  ## Returns
    - {:ok, updated_names} with updated command name mapping
    - {:error, error_type, reason} on failure
  """
  @spec update_command_names(name_map(), [module()], module()) :: result(name_map())
  def update_command_names(name_acc, commands, configurator) do
    try do
      updated_names =
        Enum.reduce(commands, name_acc, fn cmd, acc ->
          with {:ok, cmd_name} <- get_command_name(cmd) do
            Map.update(acc, cmd_name, [configurator], &[configurator | &1])
          else
            _ -> acc
          end
        end)

      {:ok, updated_names}
    rescue
      error ->
        Logger.error("Error updating command names: #{inspect(error)}")
        {:error, :command_config_error, "Failed to update command names"}
    end
  end

  @doc """
  Gets the command name from a command module.

  ## Parameters
    - command: A command module
    
  ## Returns
    - {:ok, command_name} with the command name on success
    - {:error, error_type, reason} on failure
  """
  @spec get_command_name(module()) :: result(atom())
  def get_command_name(command) do
    try do
      [{cmd_name, _}] = command.config()
      {:ok, cmd_name}
    rescue
      error ->
        Logger.error("Error getting command name from #{inspect(command)}: #{inspect(error)}")
        {:error, :command_config_error, "Failed to get command name"}
    end
  end

  @doc """
  Checks for and logs warnings about duplicated command names.

  ## Parameters
    - subcommand_names: Map of command names to their configurators
    
  ## Returns
    - :ok if the check is complete (even if duplicates are found, they're just logged)
  """
  @spec check_for_duplicated_commands(name_map()) :: :ok
  def check_for_duplicated_commands(subcommand_names) do
    duplicated_commands = Enum.filter(subcommand_names, fn {_cmd, cfgs} -> length(cfgs) > 1 end)

    if duplicated_commands != [] do
      Logger.warning(
        "Duplicate subcommand names found in the following configurators: #{inspect(duplicated_commands)}"
      )
    end

    :ok
  end

  @doc """
  Creates the final configuration by injecting subcommands.

  ## Parameters
    - combined_config: The merged base configuration
    - unique_cfg8rs: List of unique configurator modules
    
  ## Returns
    - {:ok, final_config} with the complete configuration keyword list
    - {:error, error_type, reason} on failure
  """
  @spec create_final_config(config_map(), [module()]) :: result(keyword())
  def create_final_config(combined_config, unique_cfg8rs) do
    try do
      all_commands = Enum.flat_map(unique_cfg8rs, & &1.commands())
      config_with_commands = inject_subcommands(combined_config, all_commands)
      final_config = Enum.into(config_with_commands, [])
      {:ok, final_config}
    rescue
      error ->
        Logger.error("Error creating final configuration: #{inspect(error)}")
        {:error, :configurator_setup_error, "Failed to create final configuration"}
    end
  end

  @doc """
  Injects command configurations into the base configuration.

  ## Parameters
    - config: Base configuration map
    - commands: List of command modules
    
  ## Returns
    - Configuration map with commands injected
  """
  @spec inject_subcommands(config_map(), [module()]) :: config_map()
  def inject_subcommands(config, commands) do
    with {:ok, processed_commands} <- process_commands(commands) do
      Map.update(config, :subcommands, [], fn subcommands ->
        merge_subcommands(subcommands, processed_commands)
      end)
    else
      {:error, _error_type, reason} ->
        Logger.error("Error processing commands: #{inspect(reason)}")
        # Return the original config if processing fails
        config
    end
  end

  @doc """
  Processes a list of command modules into command configurations.

  ## Parameters
    - commands: List of command modules
    
  ## Returns
    - {:ok, processed_commands} with the processed commands
    - {:error, error_type, reason} on failure
  """
  @spec process_commands([module()]) :: result(keyword())
  def process_commands(commands) do
    processed =
      Enum.reduce_while(commands, {:ok, []}, fn cmd, {:ok, acc} ->
        case get_command_config(cmd) do
          {:ok, cmd_config} -> {:cont, {:ok, [cmd_config | acc]}}
          {:error, error_type, reason} -> {:halt, {:error, error_type, reason}}
        end
      end)

    case processed do
      {:ok, cmd_list} -> {:ok, Enum.reverse(cmd_list)}
      error -> error
    end
  end

  @doc """
  Gets the configuration from a command module.

  ## Parameters
    - command_module: A command module
    
  ## Returns
    - {:ok, {command_name, command_config}} with the command configuration
    - {:error, error_type, reason} on failure
  """
  @spec get_command_config(module()) :: result({atom(), keyword()})
  def get_command_config(command_module) do
    try do
      [{cmd, config}] = command_module.config()
      {:ok, {cmd, config}}
    rescue
      error ->
        Logger.error(
          "Error getting command config from #{inspect(command_module)}: #{inspect(error)}"
        )

        {:error, :command_config_error, "Failed to get command configuration"}
    end
  end

  @doc """
  Add global CLI options to the configuration.

  These options are added at the coordinator level to ensure they're only added once,
  even when multiple configurators are used.

  ## Parameters
    - config: Configuration keyword list

  ## Returns
    - Configuration with global options added
  """
  @spec add_global_cli_options(keyword()) :: keyword()
  def add_global_cli_options(config) do
    global_options = [
      options: [
        cli_style: [
          value_name: "STYLE",
          long: "--cli-style",
          help: "Set output style (fancy, plain, dump)",
          required: false,
          parser: fn s ->
            case String.downcase(s) do
              style when style in ["fancy", "plain", "dump"] -> {:ok, String.to_atom(style)}
              _ -> {:error, "Invalid style. Must be one of: fancy, plain, dump"}
            end
          end
        ]
      ],
      flags: [
        cli_no_ansi: [
          long: "--cli-no-ansi",
          help: "Disable ANSI colors in output (same as --cli-style plain)",
          multiple: false
        ]
      ]
    ]

    Keyword.merge(config, global_options)
  end

  @doc """
  Merges subcommands, with newer commands taking precedence.

  ## Parameters
    - existing: Existing subcommands
    - new: New subcommands to merge in
    
  ## Returns
    - Merged subcommands
  """
  @spec merge_subcommands(keyword(), keyword()) :: keyword()
  def merge_subcommands(existing, new) do
    Keyword.merge(existing, new, fn _key, _val1, val2 -> val2 end)
  end
end
