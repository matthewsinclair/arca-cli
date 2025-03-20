# Integrating with Arca.Cli's New Help System

I need to update my codebase to work with the latest version of Arca.Cli which includes a new centralized help system. Please analyze my codebase and help me make the necessary changes to ensure compatibility.

## Background

Arca.Cli has implemented a new centralized help system that provides consistent help behavior across all usage scenarios. The new system:

1. Centralizes help functionality in the `Arca.Cli.Help` module
2. Uses pre-execution checks to determine when help should be shown
3. Supports help formatting via the callback system
4. Provides consistent handling for all three help scenarios:
   - Command invoked without parameters (`cli cmd`)
   - Command invoked with `--help` flag (`cli cmd --help`)
   - Command invoked with help prefix (`cli help cmd`)

## Required Changes

Please make the following changes to my codebase:

1. **Command Configuration**:
   - Review all command modules implementing `Arca.Cli.Command.CommandBehaviour`
   - Ensure they have appropriate `show_help_on_empty: true|false` configuration
   - Commands that require arguments should have `show_help_on_empty: true`
   - Commands that work without arguments should have `show_help_on_empty: false`

2. **Remove Custom Help Handling**:
   - Identify and remove any custom help handling logic in command handlers
   - Command handlers should focus on their core functionality and let the framework handle help

3. **Help Formatting (Optional)**:
   - If custom help formatting is desired, implement a callback using the new format_help event
   - Remove any existing custom help formatting logic

## Example Changes

### Before:

```elixir
defmodule MyApp.Commands.QueryCommand do
  use Arca.Cli.Command.BaseCommand
  
  config :query,
    name: "query",
    about: "Query data from the system"
    
  @impl true
  def handle(args, settings, optimus) do
    # Custom help handling
    if Enum.empty?(args) || Map.get(args, :help, false) do
      # Custom help text formatting
      format_help_text()
    else
      # Actual command logic
      process_query(args, settings)
    end
  end
  
  defp format_help_text do
    # Custom help formatting
    [
      "USAGE: query [options]",
      "Query data from the system",
      # ...
    ]
  end
end
```

### After:

```elixir
defmodule MyApp.Commands.QueryCommand do
  use Arca.Cli.Command.BaseCommand
  
  config :query,
    name: "query",
    about: "Query data from the system",
    show_help_on_empty: true # Explicitly set help behavior
    
  @impl true
  def handle(args, settings, optimus) do
    # Command logic only - no help handling
    process_query(args, settings)
  end
end

# Optional: Custom help formatting (application initialization)
if Code.ensure_loaded?(Arca.Cli.Callbacks) do
  Arca.Cli.Callbacks.register(:format_help, fn help_text ->
    # Custom help formatting logic
    formatted = MyApp.HelpFormatter.format(help_text)
    {:halt, formatted}
  end)
end
```

## Steps to Complete

1. Scan codebase for all command modules
2. Analyze each command's help behavior to determine appropriate configuration
3. Update command configurations with `show_help_on_empty` setting
4. Remove custom help detection and display logic from command handlers
5. Implement help formatting callback if custom formatting is needed