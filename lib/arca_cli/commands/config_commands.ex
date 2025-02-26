defmodule Arca.CLI.Commands.Config do
  @moduledoc """
  Config namespace commands for Arca CLI.
  
  This module demonstrates using the NamespaceCommandHelper to create
  multiple commands in the "config" namespace.
  """
  use Arca.CLI.Commands.NamespaceCommandHelper

  namespace_command :list, "List all configuration settings" do
    case Arca.CLI.load_settings() do
      %{} = settings when map_size(settings) == 0 ->
        "No configuration settings found."
        
      settings ->
        header = "Configuration Settings:\n"
        
        settings_list = settings
        |> Enum.map(fn {key, value} -> "  #{key}: #{inspect(value)}" end)
        |> Enum.join("\n")
        
        header <> settings_list
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