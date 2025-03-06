---
verblock: "06 Mar 2025:v0.2: Matthew Sinclair - Updated with comprehensive content
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
    {:arca_cli, "~> 0.3.0"}
  ]
end
```

Run mix deps.get to install the dependency:

```bash
$ mix deps.get
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
$ arca_cli --help
```

### Basic Workflow

The typical workflow with Arca.Cli involves:

1. Executing commands directly from your shell
2. Using the REPL mode for interactive sessions
3. Viewing command history and repeating previous commands
4. Managing configuration settings

## Common Tasks

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

### Managing Configuration

Viewing all settings:
```bash
$ arca_cli settings.all
```

Getting a specific setting:
```bash
$ arca_cli settings.get id
```

### Working with Command History

Viewing command history:
```bash
$ arca_cli history
```

Redoing a previous command:
```bash
$ arca_cli redo 3
```

### Executing System Commands

Running system commands:
```bash
$ arca_cli sys.cmd "ls -la"
```

Flushing system caches:
```bash
$ arca_cli sys.flush
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

### Environment Variables

| Variable           | Description                           | Default          |
|--------------------|---------------------------------------|------------------|
| ARCA_CONFIG_PATH   | Configuration directory path          | ~/.arca/         |
| ARCA_CONFIG_FILE   | Configuration filename                | arca_cli.json    |

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
