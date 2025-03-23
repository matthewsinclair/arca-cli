---
verblock: "23 Mar 2025:v0.5: Claude - Updated with automatic config path determination
23 Mar 2025:v0.4: Claude - Added Arca.Config registry integration section
19 Mar 2025:v0.3: Claude - Added output formatting integration section
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
    {:arca_cli, "~> 0.4.0"},
    # You can specify the latest Arca.Config explicitly
    {:arca_config, "~> 0.2.0", github: "organization/arca_config"}
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

| Variable           | Purpose                           | Default                           |
|--------------------|-----------------------------------|-----------------------------------|
| ARCA_CONFIG_PATH   | Configuration directory path      | ~/.arca/                          |
| ARCA_CONFIG_FILE   | Configuration filename            | {application_name}.json           |

Note: If these environment variables are not set, the configuration filename is automatically derived from your application name.

Example configuration in `.bashrc` or `.zshrc`:

```bash
export ARCA_CONFIG_PATH="$HOME/.config/arca/"
export ARCA_CONFIG_FILE="custom_config.json"
```

### Application Configuration

Configure Arca.Cli in your Elixir application:

```elixir
# In config/config.exs
config :arca_cli, :configurators, [
  YourApp.Cli.Configurator,
  Arca.Cli.Configurator.DftConfigurator
]

# Configure Arca.Config with registry and file watching options
config :arca_config,
  # Optional, defaults to the current application name
  # This name is used to generate the default config filename
  app_name: :your_app,
  # Optional, defaults to "~/.arca/"
  config_dir: "~/.arca",  
  # Optional, defaults to "{app_name}.json"
  config_file: "custom.json",    
  # Enable file watching
  watch_file: true,  
  # Check for file changes every 1000ms
  watch_interval: 1000  
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
*.json
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

### Arca.Config Registry Integration

The updated Arca.Cli uses Arca.Config's Registry integration for more robust configuration management. To properly integrate this in your application:

```elixir
defmodule YourApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Other children...

      # Add Arca.Config.Supervisor to your supervision tree
      {Arca.Config.Supervisor, []}
    ]

    # Start the supervision tree
    opts = [strategy: :one_for_one, name: YourApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

You can also set up configuration change listeners:

```elixir
defmodule YourApp.ConfigChangeHandler do
  @doc """
  Initialize configuration change handlers
  """
  def setup do
    if Code.ensure_loaded?(Arca.Config) && function_exported?(Arca.Config, :register_change_callback, 2) do
      # Register for all configuration changes
      Arca.Config.register_change_callback(:your_component, &handle_config_changes/1)
      
      # Subscribe to specific keys
      Arca.Config.subscribe("feature.enabled")
    end
  end
  
  @doc """
  Handler for all configuration changes
  """
  def handle_config_changes(config) do
    # Process configuration changes
    IO.puts("Configuration updated: #{inspect(config)}")
  end
  
  @doc """
  Handler for process that wants to receive messages about specific keys
  This would be implemented in a GenServer's handle_info callback
  """
  def handle_info({:config_updated, "feature.enabled", value}, state) do
    # React to the specific configuration change
    {:noreply, %{state | feature_enabled: value}}
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
    {:arca_cli, "~> 0.4.0"} # Update to the desired version
  ]
end
```

Then update dependencies:

```bash
mix deps.update arca_cli
```

### Upgrading Arca.Config

When upgrading to the latest version of Arca.Config with Registry integration:

1. Update the dependency in mix.exs:
   ```elixir
   def deps do
     [
       # Update to use the GitHub repository for the latest version
       {:arca_config, "~> 0.2.0", github: "organization/arca_config"}
     ]
   end
   ```

2. Ensure your application properly starts the Arca.Config supervisor:
   ```elixir
   # In your application.ex
   children = [
     # Other children...
     {Arca.Config.Supervisor, []}
   ]
   ```

3. Update any code that directly interacts with Arca.Config to use the public API:
   ```elixir
   # Use public API functions
   Arca.Config.get("key.path")
   Arca.Config.put("key.path", value)
   Arca.Config.Server.reload()
   ```

4. Take advantage of the new features:
   ```elixir
   # Register for configuration changes
   Arca.Config.register_change_callback(:component_id, fn config -> 
     # Handle changes
   end)
   
   # Subscribe to specific key changes
   Arca.Config.subscribe("specific.key.path")
   ```

5. Note that the configuration file paths are now automatically derived:
   - By default, Arca.Config will use a configuration file named after your application
   - For example, if your application is named `:my_app`, the config file will be `~/.arca/my_app.json`
   - This can be overridden with environment variables or explicit configuration

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
- Verify the configuration filename follows the expected pattern (applicationName.json)
- Set the environment variables `ARCA_CONFIG_PATH` and `ARCA_CONFIG_FILE` if using custom locations

#### Registry-Related Errors

**Problem**: You see errors related to the Arca.Config Registry.

**Solution**:
- Ensure the Arca.Config.Supervisor is started correctly
- Check that you don't have multiple instances of Arca.Config running
- Verify registry configuration in config.exs

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