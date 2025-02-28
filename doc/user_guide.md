# Arca.Cli User Guide

## Overview

Arca.Cli is a flexible command-line interface utility for Elixir projects. It provides a robust framework for building and interacting with command-line applications, featuring a modular architecture, built-in REPL mode, command history, and structured configuration management.

## Getting Started

### Installation

Add `arca_cli` to your project's dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:arca_cli, "~> 0.3.0"}
  ]
end
```

### Basic Usage

Arca.Cli comes with a set of standard commands out of the box:

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
$ arca_cli --help
```

## Command Structure

### Standard Commands

Arca.Cli includes several built-in commands:

| Command         | Description                               |
|-----------------|-------------------------------------------|
| `about`         | Display information about the CLI         |
| `history`       | Show command history                      |
| `status`        | Display current system status             |
| `settings.all`  | List all configuration settings           |
| `settings.get`  | Get a specific setting                    |
| `repl`          | Enter interactive REPL mode               |

### Namespaced Commands (Dot Notation)

Arca.Cli supports hierarchical command organization using dot notation:

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

This hierarchical organization makes the CLI more intuitive by grouping related commands under appropriate namespaces.

## REPL Mode

### Starting REPL Mode

REPL (Read-Eval-Print Loop) mode provides an interactive shell:

```bash
$ arca_cli repl
> 
```

### REPL Features

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

## Configuration Management

### Configuration Files

Arca.Cli automatically manages configuration:

- Default config directory: `~/.arca/`
- Default config file: `arca_cli.json`

### Environment Variables

You can override configuration paths with:

- `ARCA_CONFIG_PATH`: Set custom configuration directory
- `ARCA_CONFIG_FILE`: Set custom configuration filename

### Viewing and Modifying Settings

```bash
# List all settings
$ arca_cli settings.all

# Get a specific setting
$ arca_cli settings.get id

# Commands for modifying settings will depend on your specific application
```

## Command History and Redo

Arca.Cli maintains a history of executed commands:

```bash
# View command history
$ arca_cli history

# Redo a specific command by its index
$ arca_cli redo 3
```

## Extending Arca.Cli

### Creating Basic Commands

To create your own command, define a module that uses `Arca.Cli.Command.BaseCommand`:

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

### Creating Namespaced Commands

You can create namespaced commands in two ways:

#### 1. Standard Approach

```elixir
defmodule YourApp.Cli.Commands.UserProfileCommand do
  use Arca.Cli.Command.BaseCommand

  config :"user.profile",
    name: "user.profile",
    about: "Display user profile information"

  @impl true
  def handle(_args, _settings, _optimus) do
    "User profile information..."
  end
end
```

#### 2. Using NamespaceCommandHelper

The namespace helper allows defining multiple related commands in one module:

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

### Registering Your Commands

Create a configurator to register your commands with Arca.Cli:

```elixir
defmodule YourApp.Cli.Configurator do
  use Arca.Cli.Configurator.BaseConfigurator

  config :your_app_cli,
    commands: [
      YourApp.Cli.Commands.GreetCommand,
      YourApp.Cli.Commands.UserProfileCommand,
      # Auto-generated commands from namespaced modules are included automatically
    ],
    author: "Your Name",
    about: "Your CLI application",
    description: "A CLI tool for your application",
    version: "1.0.0"
end
```

Then update your application configuration:

```elixir
# In config/config.exs
config :arca_cli, :configurators, [
  YourApp.Cli.Configurator,
  Arca.Cli.Configurator.DftConfigurator
]
```

## Advanced Features

### Error Handling and Suggestions

Arca.Cli provides helpful error messages and suggestions:

```bash
$ arca_cli unknown_command
error: unknown_command: unknown command: unknown_command
Did you mean one of these? about, history, status?
```

### Command Arguments and Options

Commands can define arguments and options:

```elixir
config :example,
  name: "example",
  about: "An example command",
  args: [
    text: [
      value_name: "TEXT",
      help: "Required text argument",
      required: true
    ]
  ],
  options: [
    count: [
      value_name: "COUNT",
      short: "-c",
      long: "--count",
      help: "Number of times to repeat",
      parser: :integer
    ]
  ],
  flags: [
    verbose: [
      short: "-v",
      long: "--verbose",
      help: "Enable verbose output"
    ]
  ]
```

### Hidden Commands

You can create hidden commands that don't appear in help output:

```elixir
config :hidden_command,
  name: "hidden_command",
  about: "A hidden command",
  hidden: true
```

## Troubleshooting

### Common Issues

1. **Command Not Found**:
   - Ensure the command is correctly registered in your configurator
   - Check for typos in the command name

2. **Configuration Issues**:
   - Verify that `~/.arca/arca_cli.json` exists and has valid JSON
   - Check environment variables if you've customized config paths

3. **REPL Not Responding to Tab Completion**:
   - Some terminal emulators may require special configuration for tab completion

## Reference

### Environment Variables

| Variable           | Description                           | Default          |
|--------------------|---------------------------------------|------------------|
| ARCA_CONFIG_PATH   | Configuration directory path          | ~/.arca/         |
| ARCA_CONFIG_FILE   | Configuration filename                | arca_cli.json    |

### Standard Commands Reference

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

## Further Resources

For more information and advanced usage, see:

- [Arca.Cli GitHub Repository](https://github.com/your-org/arca_cli)
- [Arca.Cli API Documentation](https://hexdocs.pm/arca_cli)
- [Development Journal](./arca_cli_journal.md)