defmodule Arca.Cli.Commands.SettingsCommand do
  @moduledoc """
  Displays and manages configuration settings for the Arca CLI.

  This command provides access to viewing and manipulating application settings.
  """
  alias Arca.Cli
  use Arca.Cli.Command.BaseCommand
  # Removed BaseSubCommand to avoid handle/3 conflicts

  config :settings,
    name: "settings",
    about: "Display and manage configuration settings",
    # Define subcommands directly in the config
    sub_commands: [
      Arca.Cli.Commands.SettingsGetCommand,
      Arca.Cli.Commands.SettingsAllCommand
    ]

  @typedoc """
  Possible error types from settings operations
  """
  @type error_type ::
          :config_error
          | :empty_settings
          | :load_failed
          | :internal_error

  @typedoc """
  Result type for settings operations
  """
  @type result(t) :: {:ok, t} | {:error, error_type(), String.t()}

  # This function handles the main settings command
  @impl Arca.Cli.Command.CommandBehaviour
  @spec handle(map(), map(), Optimus.t()) :: map() | {:error, String.t()}
  def handle(_args, _settings, _optimus) do
    # Keep it simple to avoid typing issues
    settings_result = Cli.load_settings()

    case settings_result do
      {:ok, settings} ->
        if map_size(settings) == 0 do
          {:error, "Problem with config settings"}
        else
          settings
        end

      # This should never happen, but we're being defensive
      _ ->
        {:error, "Failed to load settings"}
    end
  end

  # Define sub_commands/0 to maintain compatibility with BaseSubCommand
  # but implement it manually instead of using the macro
  @spec sub_commands() :: [module()]
  def sub_commands() do
    [{_, config}] = __MODULE__.config()
    Keyword.get(config, :sub_commands, [])
  end
end
