---
verblock: "23 Mar 2025:v0.6: Claude - Updated with automatic config path determination
23 Mar 2025:v0.5: Claude - Updated with Arca.Config registry integration details
20 Mar 2025:v0.4: Claude - Updated with improved help system details
19 Mar 2025:v0.3: Claude - Updated with REPL callback system details
06 Mar 2025:v0.2: Matthew Sinclair - Updated with comprehensive content
06 Mar 2025:v0.1: Matthew Sinclair - Initial version"
---
# Arca.Cli User Guide

This user guide provides task-oriented instructions for using the Arca.Cli system. It explains how to accomplish common tasks and provides workflow guidance.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Getting Started](#getting-started)
4. [Common Tasks](#common-tasks)
5. [Advanced Usage](#advanced-usage)
6. [Troubleshooting](#troubleshooting)

## Introduction

Arca.Cli is a flexible command-line interface utility for Elixir projects. It provides a robust framework for building and interacting with command-line applications.

### Purpose

Arca.Cli solves several common problems in CLI development:

- Provides a consistent framework for building command-line applications
- Reduces boilerplate code required for CLI functionality
- Offers built-in features like command history, REPL mode, and configuration management
- Makes it easy to organize and extend commands with namespaces

### Core Concepts

Arca.Cli is built around these fundamental concepts:

- **Commands**: Self-contained modules that implement specific functionality
- **Namespaced Commands**: Hierarchical organization using dot notation (e.g., `sys.info`)
- **REPL Mode**: Interactive shell with command history and tab completion
- **Configurators**: Modules that register commands and define CLI behavior
- **Callbacks**: Extension system allowing customization of output formatting
- **Configuration Management**: Registry-based configuration with file watching capabilities

## Installation

### Prerequisites

- Elixir and Erlang installed on your system
- Mix build tool
- A terminal with Unicode support

### Installation Steps

Add `arca_cli` to your project's dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:arca_cli, "~> 0.4.0"}
  ]
end
```

Run mix deps.get to install the dependency:

```bash
mix deps.get
```

## Getting Started

### First Steps

After installation, you can run the CLI with its built-in commands:

```bash
# Display information about the CLI
$ arca_cli about

# Show system information
$ arca_cli sys.info

# View command history
$ arca_cli history

# Enter interactive REPL mode
$ arca_cli repl
```

To see all available commands, use the help flag:

```bash
arca_cli --help
```

### Basic Workflow

The typical workflow with Arca.Cli involves:

1. Executing commands directly from your shell
2. Using the REPL mode for interactive sessions
3. Viewing command history and repeating previous commands
4. Managing configuration settings

## Common Tasks

### Getting Help

Arca.Cli provides consistent help in three ways:

1. **Command without arguments**: For commands that require arguments

   ```bash
   $ arca_cli settings.get
   error: settings.get: missing required arguments: SETTING_ID
   ```

2. **Using the --help flag**: Works with any command

   ```bash
   $ arca_cli settings.get --help
   Get a specific setting by ID.

   USAGE:
       cli settings.get SETTING_ID
   ```

3. **Using the help prefix**: Alternative way to access help

   ```bash
   $ arca_cli help settings.get
   Get a specific setting by ID.

   USAGE:
       cli settings.get SETTING_ID
   ```

The help system works consistently across both CLI and REPL modes, and will automatically detect when help should be shown.

### Using the REPL Mode

Starting REPL mode:

```bash
$ arca_cli repl
> 
```

Once in REPL mode, you can:

1. **Execute Commands**: Type any available command to execute it

   ```
   > sys.info
   ```

2. **Tab Completion**: Press TAB to show available commands or complete a partial command

   ```
   > sys.[TAB]
   sys.cmd    sys.flush    sys.info
   ```

3. **Command History**: Use UP/DOWN arrow keys to navigate through previously executed commands

4. **Special Commands**:
   - `help`: Display available commands
   - `history`: View command history
   - `quit` or `exit`: Exit REPL mode

5. **Help in REPL**: Access help the same way as in CLI mode

   ```
   > settings.get --help
   ```

   or

   ```
   > help settings.get
   ```

### Managing Configuration

Viewing all settings:

```bash
arca_cli settings.all
```

Getting a specific setting:

```bash
arca_cli settings.get id
```

The configuration system now features real-time file watching, which means that edits made to the configuration file outside the application are automatically detected and loaded. This is useful for environments where configurations need to be updated without restarting the application.

#### Configuration File Paths

Arca.Cli and Arca.Config automatically determine the configuration paths based on the application name. By default:

- The configuration directory is set to `.app_name/` in the current directory (e.g., `.arca_cli/` for the `arca_cli` application)
- The configuration file is named `config.json`

These paths can be overridden with application-specific environment variables if needed:

```bash
# Example of custom configuration paths for the arca_cli application
export ARCA_CLI_CONFIG_PATH="/custom/path/to/config/dir/"
export ARCA_CLI_CONFIG_FILE="custom_config.json"
```

### Working with Command History

Viewing command history:

```bash
arca_cli history
```

Redoing a previous command:

```bash
arca_cli redo 3
```

### Executing System Commands

Running system commands:

```bash
arca_cli sys.cmd "ls -la"
```

Flushing system caches:

```bash
arca_cli sys.flush
```

## Advanced Usage

### Command Organization

Arca.Cli uses hierarchical command organization with dot notation:

```bash
# System-related commands
$ arca_cli sys.info      # Display system information
$ arca_cli sys.flush     # Flush system caches

# CLI-specific commands
$ arca_cli cli.history   # View CLI command history
$ arca_cli cli.status    # Show CLI status
$ arca_cli cli.redo      # Redo a previously executed command

# Development commands
$ arca_cli dev.info      # Show development information
$ arca_cli dev.deps      # List project dependencies
```

### Command Parameters

Commands can accept arguments, options, and flags:

```bash
# Command with a required argument
$ arca_cli settings.get id

# Command with an option
$ arca_cli example_command --count 5

# Command with a flag
$ arca_cli example_command --verbose
```

### Customizing Output Formatting

If you are developing an application that integrates with Arca.Cli, you can customize how output is formatted in the REPL using the callback system:

1. Check if the Callbacks module is available
2. Register a function for the `:format_output` event
3. Implement your custom formatting logic

This allows you to maintain separation of concerns without creating circular dependencies between your application and Arca.Cli.

### Working with Configuration Changes

The updated Arca.Cli includes integration with Arca.Config's callback system for configuration changes. Here's how to use it:

```elixir
# Check if callback functionality is available
if Code.ensure_loaded?(Arca.Config) && function_exported?(Arca.Config, :register_change_callback, 2) do
  # Register a callback for all configuration changes
  {:ok, :registered} = Arca.Config.register_change_callback(:my_component, fn config ->
    # Handle configuration changes
    IO.puts("Configuration was updated: #{inspect(config)}")
  end)
end
```

This is particularly useful for applications that need to react to configuration changes at runtime without polling or manual reload commands.

## Troubleshooting

### Common Issues

1. **Command Not Found**:
   - Ensure the command is correctly registered in your configurator
   - Check for typos in the command name

2. **Configuration Issues**:
   - Verify that the configuration file exists (by default at `.app_name/config.json`, e.g. `.arca_cli/config.json`)
   - Check that the configuration file contains valid JSON
   - If you're using custom paths, verify the environment variables are set correctly
   - Confirm the Arca.Config registry is running properly with `Arca.Config.Server.ping()`

3. **REPL Not Responding to Tab Completion**:
   - Some terminal emulators may require special configuration for tab completion

### Environment Variables

| Variable                     | Description                               | Default                         |
|------------------------------|-------------------------------------------|----------------------------------|
| APP_NAME_CONFIG_PATH        | Configuration directory path              | .app_name/ (e.g., .arca_cli/)    |
| APP_NAME_CONFIG_FILE        | Configuration filename                    | config.json                      |

Note that if these environment variables are not set, Arca.Config will automatically use the application name to determine the configuration file name.

### Standard Commands

| Command             | Description                 | Arguments/Options       |
|---------------------|-----------------------------|-------------------------|
| about               | Show CLI information        | None                    |
| history             | Display command history     | None                    |
| redo \<index\>      | Redo a command from history | index: Command index    |
| repl                | Enter interactive mode      | None                    |
| settings.all        | Show all settings           | None                    |
| settings.get \<id\> | Get specific setting        | id: Setting name        |
| status              | Display CLI status          | None                    |
| sys.info            | Show system information     | None                    |
| sys.flush           | Flush system caches         | None                    |
| sys.cmd \<command\> | Execute system command      | command: Command to run |