defmodule Arca.Cli.Command.BaseCommand do
  @moduledoc """
  Use an `Arca.Cli.Command.BaseCommand` to quickly and easily build a new CLI command.

  ## Command Naming Convention

  When creating a command, it's important to follow the naming convention:

  1. The module name must end with "Command" (e.g., `AboutCommand`, `StatusCommand`)
  2. The command name specified in the `config/2` macro must match the downcased module name 
     without the "Command" suffix (e.g., `:about` for `AboutCommand`, `:status` for `StatusCommand`)

  This is enforced at compile time to prevent silent failures at runtime.

  ## Example

  ```elixir
  defmodule MyApp.Cli.Commands.HelloCommand do
    use Arca.Cli.Command.BaseCommand
    
    # Correct: module is HelloCommand, command name is :hello
    config :hello,
      name: "hello",
      about: "Say hello to the user"
      
    @impl true
    def handle(_args, _settings, _optimus) do
      "Hello, world!"
    end
  end
  ```
  """
  require Logger

  @doc """
  Implement base functionality for a Command.
  """
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [config: 2]

      alias Arca.Cli.Command.BaseCommand
      import Arca.Cli.Utils
      require Logger
      @behaviour Arca.Cli.Command.CommandBehaviour

      Module.register_attribute(__MODULE__, :cmdcfg, accumulate: false)

      @doc """
      Note: Early definition of the function in Command macro to account for default values.
      """
      @impl Arca.Cli.Command.CommandBehaviour
      def handle(_args \\ nil, _settings \\ nil, _optimus \\ nil)

      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Configure a command with the given name and options.

  ## Parameters

  - `cmd`: The command name (as an atom) that will be used for CLI dispatch.
    MUST match the downcased module name without the "Command" suffix.
  - `opts`: Keyword list of options for the command configuration.

  ## Examples

  ```elixir
  # In a module named MyApp.Cli.Commands.HelloCommand:
  config :hello,
    name: "hello",
    about: "Say hello to the user"
  ```

  ## Validation

  This macro performs compile-time validation to ensure the command name
  matches the module name convention. This prevents silent runtime dispatch failures.

  ### Validation Rules

  1. The module name must end with "Command" suffix
     - Valid: `HelloCommand`, `GetDataCommand`
     - Invalid: `Hello`, `GetData`

  2. The command name (first argument to `config`) must match the downcased module name without the "Command" suffix
     - Valid: `HelloCommand` with `:hello`, `GetDataCommand` with `:get_data`
     - Invalid: `HelloCommand` with `:greeting`, `GetDataCommand` with `:fetch_data`

  ### What's Fixed

  This validation resolves a subtle bug where mismatched command names would be registered
  but fail silently at runtime during dispatch. The dispatch process in `Arca.Cli.handler_for_command/2`
  expects command names to follow this convention, and will now be validated at compile time.
  """
  defmacro config(cmd, opts) do
    quote do
      # Get the module name suffix (last part of the module name)
      module_name_parts = Module.split(__MODULE__)
      module_suffix = List.last(module_name_parts)

      # Extract the expected command name from the module suffix
      expected_cmd =
        if String.ends_with?(module_suffix, "Command") do
          suffix_without_command = String.replace_suffix(module_suffix, "Command", "")
          # Convert to the expected atom format
          String.to_atom(String.downcase(suffix_without_command))
        else
          raise ArgumentError, "Command module name must end with 'Command'"
        end

      # Handle dot notation commands (sys.info -> SysInfoCommand)
      dot_cmd =
        if is_atom(unquote(cmd)) && String.contains?(Atom.to_string(unquote(cmd)), ".") do
          parts = Atom.to_string(unquote(cmd)) |> String.split(".")

          parts
          |> Enum.map(&String.capitalize/1)
          |> Enum.join("")
          |> String.downcase()
          |> String.to_atom()
        else
          unquote(cmd)
        end

      # Validate that the command name matches the module name
      cond do
        expected_cmd == unquote(cmd) ->
          # Standard command name matches directly
          :ok

        expected_cmd == dot_cmd ->
          # Dot notation command name matches after transformation
          :ok

        true ->
          # Command name doesn't match in any format
          raise ArgumentError,
                "Command name mismatch: config defines command as #{inspect(unquote(cmd))} " <>
                  "but module name #{inspect(__MODULE__)} expects #{inspect(expected_cmd)}. " <>
                  "The command name must match the module name (without 'Command' suffix, downcased)."
      end

      @cmdcfg [{unquote(cmd), unquote(opts)}]
    end
  end

  defmacro __before_compile__(env) do
    cmdcfg = Module.get_attribute(env.module, :cmdcfg)
    escaped_cmdcfg = Macro.escape(cmdcfg)

    quote do
      @cmdcfg unquote(escaped_cmdcfg)

      @doc """
      Provide the Optimus config for the command.
      """
      @impl Arca.Cli.Command.CommandBehaviour
      def config() do
        @cmdcfg
      end

      @doc """
      Default handler for the command.
      This method is overridden by each command implementation.
      """
      @impl Arca.Cli.Command.CommandBehaviour
      def handle(_args, _settings, _optimus) do
        # If not overridden, treat as not implemented
        this_function_is_not_implemented()
        {:error, :not_implemented}
      end

      @doc """
      Properly handle the help atom and tuple in a type-safe way.
      This prevents the type violations by providing explicit type handling.
      """
      def handle(args, _settings, _optimus) when args == :help do
        :help
      end

      @doc """
      Properly handle the help tuple in a type-safe way.
      """
      def handle({:help, subcmd}, _settings, _optimus) do
        {:help, subcmd}
      end
    end
  end
end
