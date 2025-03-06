---
verblock: "06 Mar 2025:v0.1: Matthew Sinclair - Initial creation"
---
# 4. Detailed Design

## 4.1 Command System

### 4.1.1 Command Behaviour

The `Arca.Cli.Command.CommandBehaviour` defines the interface that all commands must implement:

```elixir
defmodule Arca.Cli.Command.CommandBehaviour do
  @callback config() :: Keyword.t()
  @callback handle(map(), map(), struct()) :: any()
end
```

- `config/0`: Returns the command configuration, including name, arguments, options, and flags
- `handle/3`: Implements the command logic, receiving parsed arguments, settings, and the Optimus parser

### 4.1.2 BaseCommand Implementation

The `Arca.Cli.Command.BaseCommand` provides a base implementation for commands using a macro-based DSL:

```elixir
defmodule Arca.Cli.Command.BaseCommand do
  defmacro __using__(_opts) do
    quote do
      @behaviour Arca.Cli.Command.CommandBehaviour
      import Arca.Cli.Command.BaseCommand, only: [config: 2]
      
      # Default implementations
      def config, do: []
      def handle(_args, _settings, _optimus), do: :ok
      
      defoverridable [config: 0, handle: 3]
    end
  end
  
  defmacro config(name, opts) do
    # Implementation of the config DSL
  end
end
```

### 4.1.3 Command Registration

Commands are registered through Configurators, which provide a list of command modules to the system:

```elixir
defmodule YourApp.Cli.Configurator do
  use Arca.Cli.Configurator.BaseConfigurator

  config :your_app_cli,
    commands: [
      YourApp.Cli.Commands.CustomCommand,
      YourApp.Cli.Commands.AnotherCommand,
    ],
    # Other configuration...
end
```

### 4.1.4 Command Dispatch

The command dispatch process involves:

1. Parsing the command line input
2. Identifying the target command from registered commands
3. Validating inputs against the command's argument specification
4. Invoking the command's `handle/3` function with the parsed arguments
5. Formatting and returning the result

## 4.2 REPL System

### 4.2.1 REPL Implementation

The REPL (Read-Eval-Print Loop) is implemented in the `Arca.Cli.Repl.Repl` module:

```elixir
defmodule Arca.Cli.Repl.Repl do
  def start(commands, settings, opts) do
    # Implementation of the REPL loop
  end
  
  def process_input(input, commands, settings, opts) do
    # Process user input and execute commands
  end
  
  def complete(input, commands) do
    # Implementation of tab completion
  end
end
```

### 4.2.2 Tab Completion

Tab completion is implemented through:

1. A completion function that matches partial input against available commands
2. Special handling for dot notation to complete hierarchical commands
3. Integration with `rlwrap` for enhanced terminal capabilities

Command completion logic:

```elixir
def complete(input, commands) do
  command_names = commands |> Enum.map(&(&1.config().name))
  
  matches = command_names
            |> Enum.filter(&String.starts_with?(&1, input))
            |> Enum.sort()
  
  case matches do
    [] -> []
    [exact] when exact == input -> []
    matches -> matches
  end
end
```

### 4.2.3 REPL Script Integration

The REPL integrates with external tools through shell scripts:

```bash
#!/bin/sh
# Check if rlwrap is available
if command -v rlwrap >/dev/null 2>&1; then
  # Generate completions file
  $SCRIPT_DIR/update_completions
  
  # Launch REPL with rlwrap for enhanced features
  rlwrap -f $SCRIPT_DIR/completions/completions.txt \
         -H $HOME/.arca/history \
         -C arca_cli \
         $SCRIPT_DIR/cli repl
else
  # Fall back to basic REPL
  $SCRIPT_DIR/cli repl
fi
```

## 4.3 History System

### 4.3.1 History GenServer

The History system is implemented as a GenServer for state management:

```elixir
defmodule Arca.Cli.History.History do
  use GenServer
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(opts) do
    # Load history from storage
    {:ok, %{history: [], opts: opts}}
  end
  
  def add(command) do
    GenServer.call(__MODULE__, {:add, command})
  end
  
  def get() do
    GenServer.call(__MODULE__, :get)
  end
  
  # GenServer callbacks for command handlers
end
```

### 4.3.2 History Persistence

History is persisted to a file for durability:

```elixir
defp load_history(opts) do
  path = history_path(opts)
  
  if File.exists?(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  else
    []
  end
end

defp save_history(history, opts) do
  path = history_path(opts)
  dir = Path.dirname(path)
  
  :ok = File.mkdir_p(dir)
  :ok = File.write!(path, :erlang.term_to_binary(history))
end
```

### 4.3.3 History Commands

Several commands interact with the history system:

- `HistoryCommand`: Displays the command history
- `RedoCommand`: Re-executes a command from history by index
- `CliHistoryCommand`: Namespace-specific version of the history command

## 4.4 Configuration System

### 4.4.1 Configurator Behaviour

The `Arca.Cli.Configurator.ConfiguratorBehaviour` defines the interface for configurators:

```elixir
defmodule Arca.Cli.Configurator.ConfiguratorBehaviour do
  @callback config() :: Keyword.t()
end
```

### 4.4.2 BaseConfigurator Implementation

The `Arca.Cli.Configurator.BaseConfigurator` provides a base implementation using a macro-based DSL:

```elixir
defmodule Arca.Cli.Configurator.BaseConfigurator do
  defmacro __using__(_opts) do
    quote do
      @behaviour Arca.Cli.Configurator.ConfiguratorBehaviour
      import Arca.Cli.Configurator.BaseConfigurator, only: [config: 2]
      
      # Default implementation
      def config, do: []
      
      defoverridable [config: 0]
    end
  end
  
  defmacro config(name, opts) do
    # Implementation of the config DSL
  end
end
```

### 4.4.3 Configuration Coordination

The `Arca.Cli.Configurator.Coordinator` manages multiple configurators:

```elixir
defmodule Arca.Cli.Configurator.Coordinator do
  def setup(configurators) when is_list(configurators) do
    # Merge configurations from multiple configurators
  end
  
  def setup(configurator) do
    setup([configurator])
  end
end
```

### 4.4.4 Settings Management

User settings are managed through:

1. Default settings specified in configurators
2. Environment variable overrides
3. Persistent settings stored in a JSON file
4. Runtime updates through settings commands

## 4.5 Namespace Command System

### 4.5.1 Namespace Command Helper

The `Arca.Cli.Commands.NamespaceCommandHelper` provides a DSL for defining multiple commands in the same namespace:

```elixir
defmodule Arca.Cli.Commands.NamespaceCommandHelper do
  defmacro __using__(opts) do
    namespace = Keyword.get(opts, :namespace)
    
    quote do
      import Arca.Cli.Commands.NamespaceCommandHelper, only: [namespace_command: 3]
      @namespace unquote(namespace)
    end
  end
  
  defmacro namespace_command(name, about, do: block) do
    # Implementation of the DSL for namespace commands
  end
end
```

### 4.5.2 Namespace Command Example

Example usage of the namespace command helper:

```elixir
defmodule YourApp.Cli.Commands.User do
  use Arca.Cli.Commands.NamespaceCommandHelper, namespace: "user"
  
  namespace_command :profile, "Display user profile information" do
    "User profile information..."
  end
  
  namespace_command :settings, "Show user settings" do
    "User settings..."
  end
end
```

### 4.5.3 Dot Notation Parser

The system includes specialized parsing for dot notation commands:

```elixir
def parse_command(name) do
  parts = String.split(name, ".")
  
  case parts do
    [namespace, command] -> {:namespace, namespace, command}
    [command] -> {:command, command}
    _ -> {:error, :invalid_command_format}
  end
end
```

## 4.6 Utility Functions

### 4.6.1 String Utilities

The system includes various string manipulation utilities:

```elixir
defmodule Arca.Cli.Utils.Utils do
  def to_str(value) when is_binary(value), do: value
  def to_str(value) when is_atom(value), do: Atom.to_string(value)
  def to_str(value), do: inspect(value)
  
  def type_of(value) when is_binary(value), do: "string"
  def type_of(value) when is_integer(value), do: "integer"
  def type_of(value) when is_float(value), do: "float"
  def type_of(value) when is_boolean(value), do: "boolean"
  def type_of(value) when is_list(value), do: "list"
  def type_of(value) when is_map(value), do: "map"
  def type_of(value) when is_atom(value), do: "atom"
  def type_of(_value), do: "unknown"
  
  # Other utility functions...
end
```

### 4.6.2 Timer Utility

The system includes a timer utility for measuring execution time:

```elixir
def timer(fun) when is_function(fun, 0) do
  start = :os.timestamp()
  result = fun.()
  stop = :os.timestamp()
  duration = :timer.now_diff(stop, start) / 1_000_000
  {duration, result}
end
```