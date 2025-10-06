---
verblock: "17 Apr 2025:v0.9: Claude - Added error handling system documentation"
---
# Arca.Cli Reference Guide

This reference guide provides comprehensive information about the Arca.Cli system. Unlike the task-oriented User Guide, this reference guide serves as a complete reference for all aspects of the system.

## Table of Contents

1. [Command Reference](#command-reference)
2. [API Reference](#api-reference)
3. [Directory Structure](#directory-structure)
4. [Configuration Options](#configuration-options)
5. [Extension Points](#extension-points)
6. [Error Handling System](#error-handling-system)
7. [Concepts and Terminology](#concepts-and-terminology)

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

### Context Module (`Arca.Cli.Ctx`)

The Context module provides a structured way to build command output.

#### Context Structure

```elixir
%Arca.Cli.Ctx{
  command: atom(),      # Command being executed
  args: map(),          # Parsed arguments
  options: map(),       # Command options
  output: list(),       # Structured output items
  errors: list(),       # Error messages
  status: atom(),       # :ok | :error | :warning | :pending
  cargo: map(),         # Command-specific data
  meta: map()           # Style, format, and other metadata
}
```

#### Core Functions

**`Ctx.new(command, settings)`**

Creates a new context for a command.

```elixir
ctx = Ctx.new(:my_command, settings)
```

**`Ctx.add_output(ctx, output_item)`**

Adds an output item to the context.

```elixir
ctx = Ctx.add_output(ctx, {:success, "Operation completed"})
```

**`Ctx.add_error(ctx, error_message)`**

Adds an error message to the context.

```elixir
ctx = Ctx.add_error(ctx, "File not found")
```

**`Ctx.complete(ctx, status)`**

Marks the context as complete with a final status.

```elixir
ctx = Ctx.complete(ctx, :ok)  # or :error, :warning
```

**`Ctx.put_cargo(ctx, key, value)`** / **`Ctx.get_cargo(ctx, key)`**

Stores and retrieves command-specific data.

```elixir
ctx = Ctx.put_cargo(ctx, :user_count, 42)
count = Ctx.get_cargo(ctx, :user_count)
```

#### Output Item Types

**Messages**

```elixir
{:success, message}  # Green checkmark in ANSI mode
{:error, message}    # Red X in ANSI mode
{:warning, message}  # Yellow warning symbol in ANSI mode
{:info, message}     # Cyan info symbol in ANSI mode
{:text, content}     # Plain text
```

**Tables**

```elixir
# With explicit headers (columns in header order)
{:table, rows, headers: ["Name", "Age", "City"]}

# Override column order
{:table, rows,
  headers: ["Name", "Age", "City"],
  column_order: ["City", "Age", "Name"]
}

# First row as headers (preserves row order)
{:table, [headers_row | data_rows], has_headers: true}

# Alphabetical column order (default when no headers/column_order)
{:table, rows, []}

# Descending alphabetical
{:table, rows, column_order: :desc}
```

**Table Options:**

- `headers`: List of column header names (also sets column order)
- `column_order`: Explicit column ordering (list, `:asc`, `:desc`, or custom function)
- `has_headers`: Boolean, treats first row as headers
- `border_style`: `:solid`, `:solid_rounded`, etc.
- `divide_body_rows`: Boolean, add lines between rows
- `padding_x`: Integer, horizontal padding in cells

**Lists**

```elixir
# Simple list
{:list, ["Item 1", "Item 2", "Item 3"]}

# List with title
{:list, items, title: "Available Options"}

# List with custom bullet color (ANSI mode)
{:list, items, bullet_color: :green}
```

**Interactive Elements (ANSI mode only)**

```elixir
# Spinner
{:spinner, "Loading data", fn ->
  result = perform_operation()
  {:ok, result}
end}

# Progress indicator
{:progress, "Processing files", fn ->
  result = process_files()
  {:ok, result}
end}
```

### Output Module (`Arca.Cli.Output`)

The Output module handles rendering of contexts to different formats.

**`Output.render(ctx)`**

Renders a context to a string using the appropriate style.

```elixir
output = Arca.Cli.Output.render(ctx)
IO.puts(output)
```

**Style Detection**

The output style is automatically determined:

1. Plain style if `MIX_ENV=test`
2. Plain style if `NO_COLOR=1`
3. Style from `ARCA_STYLE` environment variable (ansi, plain, json, dump)
4. Plain style if not a TTY
5. ANSI style otherwise (default for interactive terminals)

### Renderers

**AnsiRenderer** - Colored output with formatting

- Green checkmarks for success
- Red X for errors
- Yellow warnings
- Cyan info messages
- Rounded borders for tables
- Colored bullet points for lists

**PlainRenderer** - No ANSI codes

- Simple symbols (✓, ✗, ⚠)
- Box-drawing characters for tables
- Plain bullet points for lists
- Suitable for tests and non-TTY environments

**JsonRenderer** - JSON structured output

- Outputs context as JSON
- Useful for programmatic consumption

**DumpRenderer** - Raw data inspection

- Shows internal structure
- Useful for debugging

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

### Context-Based Command Definition

Commands can return structured output using the Context system:

```elixir
defmodule YourApp.Cli.Commands.UserCommand do
  use Arca.Cli.Command.BaseCommand
  alias Arca.Cli.Ctx

  config :user,
    name: "user",
    about: "Display user information",
    args: [
      username: [
        value_name: "USERNAME",
        help: "Username to lookup",
        required: true,
        parser: :string
      ]
    ]

  @impl true
  def handle(args, settings, _optimus) do
    username = args.args.username

    Ctx.new(:user, settings)
    |> fetch_user_data(username)
    |> format_output()
    |> Ctx.complete(:ok)
  end

  defp fetch_user_data(ctx, username) do
    case Database.get_user(username) do
      {:ok, user} ->
        Ctx.put_cargo(ctx, :user, user)

      {:error, reason} ->
        ctx
        |> Ctx.add_error("User not found: #{reason}")
        |> Ctx.complete(:error)
    end
  end

  defp format_output(%Ctx{status: :error} = ctx), do: ctx
  defp format_output(%Ctx{cargo: %{user: user}} = ctx) do
    ctx
    |> Ctx.add_output({:success, "User found: #{user.name}"})
    |> Ctx.add_output({:table, [user], headers: ["id", "name", "email", "created_at"]})
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
    version: "1.0.0",
    sorted: true  # Optional, defaults to true - sorts commands alphabetically
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
  # Get the application name
  app_name = Application.get_application(__MODULE__) |> Atom.to_string()
  
  # Check for application-specific environment variable override
  app_env_prefix = String.upcase(app_name)
  config_dir = System.get_env("#{app_env_prefix}_CONFIG_PATH") || ".#{app_name}/"
  
  # Get config filename from env or use default
  config_filename = System.get_env("#{app_env_prefix}_CONFIG_FILE") || "config.json"
  
  Path.join([config_dir, config_filename])
end
```

By default, if no environment variables are set:

1. The configuration directory will be `.app_name/` in the current directory (e.g., `.arca_cli/` for the `arca_cli` application)
2. The configuration file will be named `config.json`

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

| Variable                     | Description                           | Default                           |
|------------------------------|---------------------------------------|-----------------------------------|
| APP_NAME_CONFIG_PATH         | Configuration directory path          | .app_name/ (e.g., .arca_cli/)     |
| APP_NAME_CONFIG_FILE         | Configuration filename                | config.json                       |

Note: The actual environment variable names are derived from the application name. For example, for the `arca_cli` application, the environment variables would be `ARCA_CLI_CONFIG_PATH` and `ARCA_CLI_CONFIG_FILE`.

### Application Configuration

In `config/config.exs`:

```elixir
config :arca_cli, :configurators, [
  YourApp.Cli.Configurator,
  Arca.Cli.Configurator.DftConfigurator
]

# Arca.Config registry settings
config :arca_config,
  parent_app: :your_app,         # Optional, defaults to the current application name
  default_config_path: "/path",  # Optional, defaults to ".{app_name}/"
  default_config_file: "config.json", # Optional, defaults to "config.json"
  watch_file: true,              # Enable file watching
  watch_interval: 1000           # Check file changes every 1000ms
```

### Command Configuration

Available command configuration options:

| Option             | Description                                                            | Type         |
|--------------------|------------------------------------------------------------------------|--------------|
| name               | Command name                                                           | String       |
| about              | Short description                                                      | String       |
| description        | Detailed description                                                   | String       |
| args               | Command arguments                                                      | Keyword list |
| options            | Command options                                                        | Keyword list |
| flags              | Command flags                                                          | Keyword list |
| hidden             | Whether command is hidden in help                                      | Boolean      |
| show_help_on_empty | Whether to show help when invoked without args                         | Boolean      |
| sorted             | Whether commands should be sorted alphabetically (configurator option) | Boolean      |

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

## Error Handling System

The Arca CLI includes a comprehensive error handling system designed to provide consistent and informative error messages across all parts of the application.

### Error Handler Module

The `Arca.Cli.ErrorHandler` module provides the core functionality for the error handling system:

```elixir
defmodule Arca.Cli.ErrorHandler do
  @type error_type :: :command_not_found | :command_failed | :invalid_argument | # ...
  
  @type debug_info :: %{
    stack_trace: list() | nil,
    error_location: String.t() | nil,
    original_error: any() | nil,
    timestamp: DateTime.t()
  }
  
  @type enhanced_error :: {:error, error_type(), String.t(), debug_info() | nil}
  
  # Creates an enhanced error tuple with debug information
  @spec create_error(error_type(), String.t(), Keyword.t()) :: enhanced_error()
  def create_error(error_type, reason, opts \\ []) do
    # Implementation details
  end
  
  # Formats errors for display, optionally including debug information
  @spec format_error(
    enhanced_error() | {:error, error_type(), String.t()} | {:error, String.t()} | any(),
    Keyword.t()
  ) :: String.t()
  def format_error(error, opts \\ []) do
    # Implementation details
  end
  
  # Normalizes different error formats to the enhanced format
  @spec normalize_error(
    {:error, error_type(), String.t()} | {:error, String.t()} | any(),
    Keyword.t()
  ) :: enhanced_error() | any()
  def normalize_error(error, opts \\ []) do
    # Implementation details
  end
  
  # Converts an enhanced error to a standard error (for backward compatibility)
  @spec to_standard_error(enhanced_error()) :: {:error, error_type(), String.t()}
  def to_standard_error({:error, error_type, reason, _debug_info}) do
    {:error, error_type, reason}
  end
  
  # Converts an enhanced or standard error to a legacy error
  @spec to_legacy_error(enhanced_error() | {:error, error_type(), String.t()}) :: {:error, String.t()}
  def to_legacy_error({:error, _error_type, reason, _debug_info}) do
    {:error, reason}
  end
end
```

### Debug Mode Command

The `cli.debug` command allows users to toggle detailed error information:

```elixir
defmodule Arca.Cli.Commands.CliDebugCommand do
  use Arca.Cli.Command.BaseCommand
  
  config :"cli.debug",
    name: "cli.debug",
    about: "Show or toggle debug mode for detailed error information",
    args: [
      toggle: [
        value_name: "on|off",
        help: "Turn debug mode on or off",
        required: false
      ]
    ]
  
  @impl true
  def handle(args, _settings, _optimus) do
    toggle = args.args.toggle
    current = Application.get_env(:arca_cli, :debug_mode, false)
    
    case toggle do
      nil -> "Debug mode is currently #{if current, do: "ON", else: "OFF"}"
      "on" -> 
        Application.put_env(:arca_cli, :debug_mode, true)
        "Debug mode is now ON"
      "off" -> 
        Application.put_env(:arca_cli, :debug_mode, false)
        "Debug mode is now OFF"
      _ -> 
        {:error, :invalid_argument, "Invalid value '#{toggle}'. Use 'on' or 'off'."}
    end
  end
end
```

### Standard Error Types

The system defines standardized error types for consistent error classification:

| Error Type           | Description                                               |
|----------------------|-----------------------------------------------------------|
| `:command_not_found` | No command was found matching the given name              |
| `:command_failed`    | A command failed during execution                         |
| `:invalid_argument`  | An invalid argument was provided to a command             |
| `:config_error`      | An error occurred in the configuration system             |
| `:file_not_found`    | A requested file could not be found                       |
| `:file_not_readable` | A file exists but cannot be read due to permissions       |
| `:file_not_writable` | A file cannot be written to due to permissions            |
| `:decode_error`      | Error decoding data (e.g., JSON parsing)                  |
| `:encode_error`      | Error encoding data (e.g., JSON serialization)            |
| `:validation_error`  | Command validation failed                                 |
| `:command_mismatch`  | Command name mismatch between registration and execution  |
| `:help_requested`    | User requested help for a command                         |
| `:unknown_error`     | Unclassified error without a specific type                |

### Enhanced Error Format

The enhanced error format provides comprehensive error information:

```elixir
{:error, :command_failed, "Failed to execute command", %{
  stack_trace: [
    {Arca.Cli.Commands.ExampleCommand, :handle, 3, [file: "lib/arca_cli/commands/example_command.ex", line: 25]},
    {Arca.Cli, :execute_command, 5, [file: "lib/arca_cli.ex", line: 672]},
    {Arca.Cli, :handle_subcommand, 4, [file: "lib/arca_cli.ex", line: 614]},
    {Arca.Cli, :main, 1, [file: "lib/arca_cli.ex", line: 233]}
  ],
  error_location: "Arca.Cli.Commands.ExampleCommand.handle/3",
  original_error: %RuntimeError{message: "Something went wrong"},
  timestamp: ~U[2025-04-17 15:30:45.123Z]
}}
```

When debug mode is enabled, the formatted output includes this detailed information:

```
Error (command_failed): Failed to execute command
Debug Information:
  Time: 2025-04-17 15:30:45.123Z
  Location: Arca.Cli.Commands.ExampleCommand.handle/3
  Original error: %RuntimeError{message: "Something went wrong"}
  Stack trace:
    Elixir.Arca.Cli.Commands.ExampleCommand.handle/3 (lib/arca_cli/commands/example_command.ex:25)
    Elixir.Arca.Cli.execute_command/5 (lib/arca_cli.ex:672)
    Elixir.Arca.Cli.handle_subcommand/4 (lib/arca_cli.ex:614)
    Elixir.Arca.Cli.main/1 (lib/arca_cli.ex:233)
```

### Using Error Handling in Custom Commands

When implementing custom commands, you can leverage the error handling system:

```elixir
defmodule YourApp.Cli.Commands.CustomCommand do
  use Arca.Cli.Command.BaseCommand
  alias Arca.Cli.ErrorHandler
  
  config :custom,
    name: "custom",
    about: "Example custom command"
    
  @impl true
  def handle(_args, _settings, _optimus) do
    case perform_operation() do
      {:ok, result} ->
        # Success case
        result
        
      {:error, reason} when is_binary(reason) ->
        # Convert legacy error to enhanced error
        ErrorHandler.create_error(
          :command_failed,
          reason,
          error_location: "#{__MODULE__}.handle/3"
        )
        
      error = {:error, _type, _reason} ->
        # Already using standard error format, convert to enhanced
        ErrorHandler.normalize_error(error, error_location: "#{__MODULE__}.handle/3")
        
      error = {:error, _type, _reason, _debug} ->
        # Already using enhanced format
        error
    end
  rescue
    e ->
      # Create enhanced error with stack trace
      ErrorHandler.create_error(
        :command_failed,
        "Custom command failed: #{Exception.message(e)}",
        stack_trace: __STACKTRACE__,
        original_error: e,
        error_location: "#{__MODULE__}.handle/3"
      )
  end
  
  defp perform_operation do
    # Your implementation...
  end
end
```

### Error Handler Testing

When testing commands that use the error handling system:

```elixir
defmodule YourApp.Test.CustomCommandTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  
  test "handle/3 returns enhanced error tuple for invalid input" do
    result = YourApp.Cli.Commands.CustomCommand.handle(
      %{args: %{value: "invalid"}},
      %{},
      nil
    )
    
    # Test the error structure
    assert {:error, :invalid_argument, "Invalid value", debug_info} = result
    assert is_map(debug_info)
    assert debug_info.error_location == "YourApp.Cli.Commands.CustomCommand.handle/3"
    
    # Test the formatted output with debug enabled
    Application.put_env(:arca_cli, :debug_mode, true)
    output = capture_io(fn ->
      Arca.Cli.ErrorHandler.format_error(result, debug: true)
      |> IO.puts()
    end)
    
    assert output =~ "Error (invalid_argument): Invalid value"
    assert output =~ "Debug Information:"
    assert output =~ "Location: YourApp.Cli.Commands.CustomCommand.handle/3"
  end
end
```

### Error Handling Macros

The error handling system includes macros to simplify the creation and formatting of errors with automatic location tracking:

```elixir
defmodule Arca.Cli.ErrorHandler do
  # Existing functions...
  
  defmacro __using__(_) do
    quote do
      import Arca.Cli.ErrorHandler, only: [create_and_format_error: 2, create_and_format_error: 3]
    end
  end
  
  @doc """
  Creates and formats an error with automatic location tracking.
  
  This macro automatically adds the current module and function name 
  to the error location, simplifying error creation and formatting
  in a single operation.
  """
  defmacro create_and_format_error(error_type, message, opts \\ []) do
    quote do
      error_location = "#{__MODULE__}.#{elem(__ENV__.function, 0)}/#{elem(__ENV__.function, 1)}"
      
      unquote(opts)
      |> Keyword.put(:error_location, error_location)
      |> (&Arca.Cli.ErrorHandler.create_error(unquote(error_type), unquote(message), &1)).()
      |> Arca.Cli.ErrorHandler.format_error()
    end
  end
end
```

Using this macro in your commands dramatically simplifies error handling:

```elixir
defmodule YourApp.Cli.Commands.ExampleCommand do
  use Arca.Cli.Command.BaseCommand
  use Arca.Cli.ErrorHandler  # Import the error handling macros
  
  config :example,
    name: "example",
    about: "Example command"
    
  @impl true
  def handle(args, _settings, _optimus) do
    case validate_args(args) do
      :ok -> 
        execute_command(args)
        
      {:error, reason} ->
        # Use the macro for simplified error handling
        create_and_format_error(:validation_error, reason)
    end
  end
  
  defp validate_args(%{args: %{limit: limit}}) when not is_integer(limit) or limit <= 0 do
    {:error, "Limit must be a positive integer"}
  end
  
  defp validate_args(_), do: :ok
  
  defp execute_command(args) do
    # Command implementation
  end
end
```

The benefits of using the macro include:

1. **Automatic location tracking**: No need to manually construct error locations
2. **Reduced boilerplate**: Single function call instead of multiple steps
3. **Consistent formatting**: Ensures all errors are handled similarly
4. **Less error-prone**: Eliminates potential errors in manual location construction

### Planned Future Enhancements

Future versions of the error handling system may include:

1. Command-specific error handling protocols
2. ANSI color formatting for improved readability
3. Interactive debugging capabilities
4. Clickable file paths in terminal output
5. Additional error handling macros for specialized use cases

## Concepts and Terminology

| Term                     | Definition                                                                                  |
|--------------------------|---------------------------------------------------------------------------------------------|
| Command                  | A self-contained unit of functionality that can be executed from the CLI                    |
| Configurator             | A module that registers commands and defines CLI configuration                              |
| REPL                     | Read-Eval-Print Loop, an interactive shell for running commands                             |
| Dot Notation             | A naming convention for organizing commands hierarchically (e.g., `sys.info`)               |
| NamespaceCommandHelper   | A helper module for defining multiple commands in the same namespace                        |
| BaseCommand              | The base module for defining commands                                                       |
| BaseSubCommand           | The base module for defining subcommands                                                    |
| Callbacks                | Extension system allowing external applications to customize behavior                       |
| Callback Chain           | Multiple callbacks executed in reverse registration order (last registered, first executed) |
| Registry                 | Elixir's built-in process registry, used by Arca.Config for process management              |
| File Watching            | Mechanism to detect and automatically reload configuration file changes                     |
| Application-based Config | The system of deriving configuration paths from the application name                        |
| Command Sorting          | Feature that determines whether commands are displayed in alphabetical order                |
|                          | (case-insensitive, default) or in the order they were defined                               |
| ErrorHandler             | Central module for standardized error handling, formatting, and normalization               |
| Enhanced Error Tuple     | Four-element error tuple with debug information: `{:error, error_type, reason, debug_info}` |
| Debug Mode               | Optional mode that displays detailed error information including stack traces               |
| create_error_with_location | Macro that creates errors with automatic location tracking                            |
| create_and_format_error_with_location | Macro that creates and formats errors with automatic location tracking              |
| err_cloc                 | Shorthand alias for create_error_with_location                                        |
| err_cfloc                | Shorthand alias for create_and_format_error_with_location                             |
