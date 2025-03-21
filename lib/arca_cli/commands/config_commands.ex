defmodule Arca.Cli.Commands.Config do
  @moduledoc """
  Config namespace commands for Arca CLI.

  This module demonstrates using the NamespaceCommandHelper to create
  multiple commands in the "config" namespace.
  """
  use Arca.Cli.Commands.NamespaceCommandHelper

  namespace_command :list, "List all configuration settings" do
    # Use a simpler approach that satisfies the type checker
    result = Arca.Cli.load_settings()

    # Explicitly handle each possible return type
    case result do
      {:ok, settings} ->
        if map_size(settings) == 0 do
          "No configuration settings found."
        else
          header = "Configuration Settings:\n"

          settings_list =
            settings
            |> Enum.map(fn {key, value} -> "  #{key}: #{inspect(value)}" end)
            |> Enum.join("\n")

          header <> settings_list
        end

      # This is intentionally here for future compatibility,
      # even though the type checker might not recognize it
      _ ->
        "Error loading settings"
    end
  end

  namespace_command :get, "Get a specific configuration setting" do
    """
    Usage: config.get <setting_name>

    Gets a specific configuration setting by name.
    Example: config.get username
    """
  end

  namespace_command :help, "Display help for config commands" do
    # Return as a simple string instead of a heredoc to avoid formatting issues
    "Config Namespace Commands:\n\n" <>
      "config.list - List all configuration settings\n" <>
      "config.get  - Get a specific configuration setting\n" <>
      "config.help - Display this help message\n\n" <>
      "These commands help manage the application configuration."
  end
end
