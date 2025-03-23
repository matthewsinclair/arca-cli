---
verblock: "23 Mar 2025:v0.6: Claude - Updated with automatic config path determination
23 Mar 2025:v0.5: Claude - Added Arca.Config registry integration documentation
20 Mar 2025:v0.4: Claude - Added help system documentation
19 Mar 2025:v0.3: Claude - Added callback system documentation
06 Mar 2025:v0.2: Matthew Sinclair - Updated with Arca.Cli specific reference content
06 Mar 2025:v0.1: Matthew Sinclair - Initial version"
---
# Arca.Cli Reference Guide

This reference guide provides comprehensive information about the Arca.Cli system. Unlike the task-oriented User Guide, this reference guide serves as a complete reference for all aspects of the system.

## Table of Contents

1. [Command Reference](#command-reference)
2. [API Reference](#api-reference)
3. [Directory Structure](#directory-structure)
4. [Configuration Options](#configuration-options)
5. [Extension Points](#extension-points)
6. [Concepts and Terminology](#concepts-and-terminology)

## Command Reference

### Standard Commands

#### `about`

Displays information about the CLI.

**Usage:**

```bash
arca_cli about
```

**Example Output:**

```
Arca.Cli v0.4.0
Copyright (c) 2024, Your Organization
```

#### `history`

Displays command history.

**Usage:**

```bash
arca_cli history
```

**Example Output:**

```
Command History:
1: about
2: sys.info
3: settings.all
```

#### `redo <index>`

Reruns a command from history.

**Usage:**

```bash
arca_cli redo <index>
```

**Parameters:**

- `index`: The index of the command in history (required)

**Example:**

```bash
arca_cli redo 2
```

#### `repl`

Enters interactive REPL mode.

**Usage:**

```bash
arca_cli repl
```

#### `settings.all`

Lists all configuration settings.

**Usage:**

```bash
arca_cli settings.all
```

#### `settings.get <id>`

Gets a specific setting.

**Usage:**

```bash
arca_cli settings.get <id>
```

**Parameters:**

- `id`: Setting identifier (required)

**Example:**

```bash
arca_cli settings.get cli.history.max_size
```

#### `status`

Displays CLI status.

**Usage:**

```bash
arca_cli status
```

#### `sys.info`

Shows system information.

**Usage:**

```bash
arca_cli sys.info
```

#### `sys.flush`

Flushes system caches.

**Usage:**

```bash
arca_cli sys.flush
```

#### `sys.cmd <command>`

Executes a system command.

**Usage:**

```bash
arca_cli sys.cmd <command>
```

**Parameters:**

- `command`: The system command to execute (required)

**Example:**

```bash
arca_cli sys.cmd "ls -la"
```

### Development Commands

#### `dev.info`

Shows development information.

**Usage:**

```bash
arca_cli dev.info
```

#### `dev.deps`

Lists project dependencies.

**Usage:**

```bash
arca_cli dev.deps
```

## API Reference

### Command Definition

Commands are defined using the `Arca.Cli.Command.BaseCommand` module:

```elixir
defmodule YourApp.Cli.Commands.GreetCommand do
  use Arca.Cli.Command.BaseCommand

  config :greet,
    name: "greet",
    about: "Greet the user",
    args: [
      name: [
        value_name: "NAME",
        help: "Name to greet",
        required: true,
        parser: :string
      ]
    ]

  @impl true
  def handle(args, _settings, _optimus) do
    "Hello, #{args.args.name}!"
  end
end
```

### Namespaced Command Definition

Using the NamespaceCommandHelper for multiple related commands:

```elixir
defmodule YourApp.Cli.Commands.User do
  use Arca.Cli.Commands.NamespaceCommandHelper
  
  namespace_command :profile, "Display user profile information" do
    "User profile information..."
  end
  
  namespace_command :settings, "Show user settings" do
    "User settings..."
  end
end
```

### Configurator Definition

Configurators register commands with Arca.Cli:

```elixir
defmodule YourApp.Cli.Configurator do
  use Arca.Cli.Configurator.BaseConfigurator

  config :your_app_cli,
    commands: [
      YourApp.Cli.Commands.GreetCommand,
      YourApp.Cli.Commands.UserProfileCommand,
    ],
    author: "Your Name",
    about: "Your CLI application",
    description: "A CLI tool for your application",
    version: "1.0.0"
end
```

### Help System Configuration

Commands can control their help behavior by setting the `show_help_on_empty` option:

```elixir
defmodule YourApp.Cli.Commands.QueryCommand do
  use Arca.Cli.Command.BaseCommand
  
  config :query,
    name: "query",
    about: "Query data from the system",
    show_help_on_empty: true,  # Show help when invoked without arguments
    args: [
      id: [
        value_name: "ID",
        help: "ID to query",
        required: true,
        parser: :string
      ]
    ]
  
  @impl true
  def handle(args, settings, optimus) do
    # Command logic - help is handled automatically
    execute_query(args.args.id, settings)
  end
end
```

Setting `show_help_on_empty: true` causes the command to show help when invoked without arguments.
Setting `show_help_on_empty: false` (the default) lets the command execute normally without arguments.

### Configuration System

Arca.Cli uses the Arca.Config library for configuration management. The updated implementation includes Registry integration, file watching, and a callback system:

```elixir
# Loading settings (internal implementation)
def load_settings() do
  case Arca.Config.Server.reload() do
    {:ok, _} -> {:ok, true}
    {:error, reason} -> {:error, reason}
  end
end

# Retrieving a setting
def get_setting(setting_id) do
  case Arca.Config.get(setting_id) do
    {:ok, value} -> {:ok, value}
    {:error, :not_found} -> {:error, "Setting not found: #{setting_id}"}
    {:error, reason} -> {:error, "Error retrieving setting: #{inspect(reason)}"}
  end
end

# Saving settings
def save_settings(settings) do
  Enum.reduce_while(settings, {:ok, []}, fn {key, value}, {:ok, acc} ->
    case Arca.Config.put(key, value) do
      {:ok, _} -> {:cont, {:ok, [{key, value} | acc]}}
      error -> {:halt, error}
    end
  end)
end

# Registering for configuration changes
def register_for_changes(component_id, callback_fn) do
  Arca.Config.register_change_callback(component_id, callback_fn)
end

# Subscribing to specific config key changes
def subscribe_to_key_changes(key_path) do
  Arca.Config.subscribe(key_path)
end
```

The Registry integration provides better process isolation and resiliency, while file watching enables automatic reloading of configuration when changes are detected.

#### Configuration File Path Determination

Arca.Config automatically determines the configuration file paths based on the hosting application's name:

```elixir
# Example of how configuration file paths are determined
defp determine_config_path do
  # Check for environment variable override
  config_dir = System.get_env("ARCA_CONFIG_PATH") || "~/.arca/"
  
  # Derive filename from application name if not overridden
  app_name = Application.get_application(__MODULE__) |> Atom.to_string()
  config_filename = System.get_env("ARCA_CONFIG_FILE") || "#{app_name}.json"
  
  Path.join([config_dir, config_filename])
end
```

By default, if no environment variables are set:

1. The configuration directory will be `~/.arca/`
2. The configuration file will be named after the application (e.g., `arca_cli.json` for the `arca_cli` application)

## Directory Structure

```
lib/
├── arca_cli.ex             # Main entry point
├── arca_cli/               # Core modules
│   ├── commands/           # Built-in commands
│   │   ├── about_command.ex
│   │   ├── base_command.ex
│   │   ├── base_sub_command.ex
│   │   ├── command_behaviour.ex
│   │   └── ...
│   ├── configurator/       # Configuration modules
│   │   ├── base_configurator.ex
│   │   ├── configurator_behaviour.ex
│   │   ├── coordinator.ex
│   │   └── dft_configurator.ex
│   ├── help.ex             # Centralized help system
│   ├── history/            # Command history modules
│   │   └── history.ex
│   ├── repl/               # REPL modules
│   │   └── repl.ex
│   ├── supervisor/         # Supervision modules
│   │   └── history_supervisor.ex
│   └── utils/              # Utility functions
│       └── utils.ex
└── mix/                    # Mix tasks
    └── tasks/
        └── arca_cli.ex
```

## Configuration Options

### Environment Variables

| Variable           | Description                           | Default                           |
|--------------------|---------------------------------------|-----------------------------------|
| ARCA_CONFIG_PATH   | Configuration directory path          | ~/.arca/                          |
| ARCA_CONFIG_FILE   | Configuration filename                | {application_name}.json           |

Note: If these environment variables are not set, Arca.Config automatically determines the configuration file name based on the application name.

### Application Configuration

In `config/config.exs`:

```elixir
config :arca_cli, :configurators, [
  YourApp.Cli.Configurator,
  Arca.Cli.Configurator.DftConfigurator
]

# Arca.Config registry settings
config :arca_config,
  app_name: :your_app,           # Optional, defaults to the current application name
  config_dir: "~/.arca",         # Optional, defaults to "~/.arca/"
  config_file: "custom.json",    # Optional, defaults to "{app_name}.json"
  watch_file: true,              # Enable file watching
  watch_interval: 1000           # Check file changes every 1000ms
```

### Command Configuration

Available command configuration options:

| Option      | Description                                   | Type             |
|-------------|-----------------------------------------------|------------------|
| name        | Command name                                  | String           |
| about       | Short description                             | String           |
| description | Detailed description                          | String           |
| args        | Command arguments                             | Keyword list     |
| options     | Command options                               | Keyword list     |
| flags       | Command flags                                 | Keyword list     |
| hidden      | Whether command is hidden in help             | Boolean          |
| show_help_on_empty | Whether to show help when invoked without args | Boolean  |

## Extension Points

### Creating Custom Commands

1. Define a command module that uses `Arca.Cli.Command.BaseCommand`
2. Implement the `handle/3` callback
3. Register the command in a configurator

### Creating Custom Configurators

1. Define a configurator module that uses `Arca.Cli.Configurator.BaseConfigurator`
2. Define your CLI configuration using the `config` macro
3. Register the configurator in your application config

### Adding Subcommands

1. Define a parent command module
2. Define subcommand modules that use `Arca.Cli.Command.BaseSubCommand`
3. Register the parent command in a configurator

### Customizing Help Display

The help system can be extended through callbacks:

1. Register a callback for `:format_help` using `Arca.Cli.Callbacks.register/2`
2. Implement a formatting function that transforms the help text
3. Return a modified help display

Example:

```elixir
# Check if the callbacks system is available
if Code.ensure_loaded?(Arca.Cli.Callbacks) do
  # Register a callback for format_help
  Arca.Cli.Callbacks.register(:format_help, fn help_text ->
    # Add branding or customize the help display
    branded_help = ["MyApp CLI Help:" | help_text]
    
    # Apply custom styling
    styled_help = Enum.map(branded_help, &MyApp.Formatters.colorize/1)
    
    # Return the formatted help
    {:halt, styled_help}
  end)
end
```

### Customizing Output Formatting

Arca.Cli includes a callback system that allows external applications to customize output formatting:

1. Register a callback for `:format_output` using `Arca.Cli.Callbacks.register/2`
2. Implement a formatting function that transforms the output
3. Return either a formatted string, `{:cont, value}` to continue the callback chain, or `{:halt, result}` to stop the chain

Example:

```elixir
# Check if the callbacks system is available
if Code.ensure_loaded?(Arca.Cli.Callbacks) do
  # Register a callback for format_output
  Arca.Cli.Callbacks.register(:format_output, fn output ->
    # Format the output as needed
    formatted = format_result(output)
    
    # Stop processing and use this result
    {:halt, formatted}
  end)
end
```

### Configuration Change Reactions

The updated Arca.Cli integrates with Arca.Config's callback system to react to configuration changes:

```elixir
# Register for all configuration changes
if Code.ensure_loaded?(Arca.Config) && function_exported?(Arca.Config, :register_change_callback, 2) do
  Arca.Config.register_change_callback(:my_component, fn config ->
    # React to configuration changes
    Logger.info("Configuration updated: #{inspect(config)}")
    apply_new_configuration(config)
  end)
end

# Subscribe to specific configuration key changes
if Code.ensure_loaded?(Arca.Config) && function_exported?(Arca.Config, :subscribe, 1) do
  Arca.Config.subscribe("app.feature.enabled")
  
  # In a process (such as a GenServer), handle the subscription messages:
  def handle_info({:config_updated, "app.feature.enabled", true}, state) do
    # Enable feature
    {:noreply, %{state | feature_enabled: true}}
  end
  
  def handle_info({:config_updated, "app.feature.enabled", false}, state) do
    # Disable feature
    {:noreply, %{state | feature_enabled: false}}
  end
end
```

## Concepts and Terminology

| Term         | Definition                                                                          |
|--------------|------------------------------------------------------------------------------------|
| Command      | A self-contained unit of functionality that can be executed from the CLI            |
| Configurator | A module that registers commands and defines CLI configuration                      |
| REPL         | Read-Eval-Print Loop, an interactive shell for running commands                     |
| Dot Notation | A naming convention for organizing commands hierarchically (e.g., `sys.info`)       |
| NamespaceCommandHelper | A helper module for defining multiple commands in the same namespace      |
| BaseCommand  | The base module for defining commands                                               |
| BaseSubCommand | The base module for defining subcommands                                          |
| Callbacks    | Extension system allowing external applications to customize behavior               |
| Callback Chain | Multiple callbacks executed in reverse registration order (last registered, first executed) |
| Registry     | Elixir's built-in process registry, used by Arca.Config for process management      |
| File Watching | Mechanism to detect and automatically reload configuration file changes            |
| Application-based Config | The system of deriving configuration paths from the application name    |