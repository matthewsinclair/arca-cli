---
verblock: "19 Mar 2025:v0.3: Claude - Added output formatting integration section
06 Mar 2025:v0.2: Matthew Sinclair - Updated with Arca.Cli specific deployment content
06 Mar 2025:v0.1: Matthew Sinclair - Initial version"
---
# Arca.Cli Deployment Guide

This deployment guide provides instructions for deploying the Arca.Cli system in various environments. It covers installation, configuration, and integration with other tools and workflows.

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Integration](#integration)
4. [Maintenance](#maintenance)
5. [Upgrading](#upgrading)
6. [Troubleshooting](#troubleshooting)

## Installation

### System Requirements

- Elixir 1.14 or later
- Erlang 25 or later
- POSIX-compatible shell environment (bash, zsh)
- Terminal with Unicode support

### Installation Methods

#### As a Project Dependency

The most common way to use Arca.Cli is as a dependency in your Elixir project:

```bash
# Create a new Elixir project (if needed)
mix new your_app

# Navigate to your project
cd your_app
```

Add Arca.Cli to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:arca_cli, "~> 0.3.0"}
  ]
end
```

Install the dependency:

```bash
mix deps.get
```

#### Standalone Installation

To install Arca.Cli as a standalone executable:

```bash
# Clone the repository
git clone https://github.com/your-org/arca_cli.git

# Navigate to the directory
cd arca_cli

# Build the executable
mix escript.build

# Move the executable to a directory in your PATH
sudo mv arca_cli /usr/local/bin/
```

#### Installation Verification

Verify the installation:

```bash
# If installed as a dependency
mix arca_cli --help

# If installed as a standalone executable
arca_cli --help
```

## Configuration

### Environment Variables

Configure Arca.Cli behavior using these environment variables:

| Variable           | Purpose                           | Default          |
|--------------------|-----------------------------------|------------------|
| ARCA_CONFIG_PATH   | Configuration directory path      | ~/.arca/         |
| ARCA_CONFIG_FILE   | Configuration filename            | arca_cli.json    |

Example configuration in `.bashrc` or `.zshrc`:

```bash
export ARCA_CONFIG_PATH="$HOME/.config/arca/"
export ARCA_CONFIG_FILE="config.json"
```

### Application Configuration

Configure Arca.Cli in your Elixir application:

```elixir
# In config/config.exs
config :arca_cli, :configurators, [
  YourApp.Cli.Configurator,
  Arca.Cli.Configurator.DftConfigurator
]
```

### Project Configuration

Create a custom configurator for your project:

```elixir
defmodule YourApp.Cli.Configurator do
  use Arca.Cli.Configurator.BaseConfigurator

  config :your_app_cli,
    commands: [
      YourApp.Cli.Commands.CustomCommand,
    ],
    author: "Your Name",
    about: "Your CLI application",
    description: "A CLI tool for your application",
    version: "1.0.0"
end
```

## Integration

### Version Control Integration

#### Recommended .gitignore

```
# Arca.Cli files
.arca/
arca_cli.json
```

### Mix Tasks Integration

Create custom Mix tasks that use Arca.Cli:

```elixir
defmodule Mix.Tasks.YourApp.Cli do
  use Mix.Task

  @shortdoc "Run the YourApp CLI"
  
  def run(args) do
    Application.ensure_all_started(:your_app)
    Arca.Cli.main(args)
  end
end
```

### Output Formatting Integration

To customize Arca.Cli's output formatting from your application:

```elixir
defmodule YourApp.Formatter do
  @doc """
  Initializes the integration with Arca.Cli
  """
  def setup do
    if Code.ensure_loaded?(Arca.Cli.Callbacks) do
      Arca.Cli.Callbacks.register(:format_output, &format_output/1)
    end
  end
  
  @doc """
  Custom formatter for Arca.Cli output
  """
  def format_output(output) do
    # Apply your formatting logic here
    formatted = YourApp.FormatContext.process(output)
    
    # Return formatted output and stop the callback chain
    {:halt, formatted}
  end
end
```

Call the setup function when your application starts:

```elixir
defmodule YourApp.Application do
  use Application
  
  def start(_type, _args) do
    # Setup the Arca.Cli integration if available
    YourApp.Formatter.setup()
    
    # ... rest of your application start function
  end
end
```

### CI/CD Integration

For CI/CD environments, ensure the configuration path is set correctly:

```yaml
# GitHub Actions example
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      ARCA_CONFIG_PATH: "/tmp/arca"
    steps:
      - uses: actions/checkout@v3
      - uses: erlef/setup-beam@v1
        with:
          otp-version: 25
          elixir-version: 1.14
      - run: mix deps.get
      - run: mix test
```

### IDE Integration

#### Visual Studio Code

Add launch configuration for debugging:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "mix_task",
      "name": "Run CLI",
      "request": "launch",
      "task": "arca_cli",
      "taskArgs": ["about"],
      "env": {
        "ARCA_CONFIG_PATH": "${workspaceFolder}/.arca"
      }
    }
  ]
}
```

## Maintenance

### Regular Maintenance Tasks

- Update dependencies periodically with `mix deps.update arca_cli`
- Clean up command history if it grows too large
- Review and update custom commands as needed

### Backup Practices

- Include configuration files in backups
- Store custom command implementations in version control
- Document command workflows for knowledge sharing

## Upgrading

### Upgrading Arca.Cli

To upgrade Arca.Cli to the latest version:

```elixir
# In mix.exs
def deps do
  [
    {:arca_cli, "~> 0.3.0"} # Update to the desired version
  ]
end
```

Then update dependencies:

```bash
mix deps.update arca_cli
```

### Migrating Between Major Versions

When upgrading between major versions:

1. Review the changelog for breaking changes
2. Update any custom commands to match new interfaces
3. Migrate configuration to the new format if necessary
4. Run tests to verify compatibility
5. Update documentation to reflect changes

## Troubleshooting

### Common Issues

#### Command Not Found

**Problem**: The CLI reports that a command cannot be found.

**Solution**: 
- Verify the command is registered in your configurator
- Check for typos in the command name
- Ensure your configurator is registered in the application configuration

#### Configuration File Issues

**Problem**: The CLI cannot find or load the configuration file.

**Solution**:
- Check that the configuration directory exists (`~/.arca/` by default)
- Verify the configuration file is valid JSON
- Set the environment variables `ARCA_CONFIG_PATH` and `ARCA_CONFIG_FILE` if using custom locations

#### REPL Tab Completion Not Working

**Problem**: Tab completion doesn't work in REPL mode.

**Solution**:
- Install `rlwrap` for improved REPL experience (`brew install rlwrap` on macOS)
- Some terminals may require additional configuration for proper tab completion

### Diagnostic Commands

Use these commands to diagnose issues:

```bash
# Show CLI status and configuration
arca_cli status

# Show system information
arca_cli sys.info

# List all settings
arca_cli settings.all
```

### Getting Help

For additional help:

- Check the [Arca.Cli Documentation](https://hexdocs.pm/arca_cli)
- Review the [GitHub repository](https://github.com/your-org/arca_cli)
- Join the [Elixir Forum](https://elixirforum.com) to ask questions
