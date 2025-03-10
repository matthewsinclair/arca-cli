---
verblock: "06 Mar 2025:v0.2: Matthew Sinclair - Updated with Arca.Cli specific reference content
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
Arca.Cli v0.3.0
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

| Variable           | Description                           | Default          |
|--------------------|---------------------------------------|------------------|
| ARCA_CONFIG_PATH   | Configuration directory path          | ~/.arca/         |
| ARCA_CONFIG_FILE   | Configuration filename                | arca_cli.json    |

### Application Configuration

In `config/config.exs`:

```elixir
config :arca_cli, :configurators, [
  YourApp.Cli.Configurator,
  Arca.Cli.Configurator.DftConfigurator
]
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
