defmodule Arca.Cli.Callbacks do
  @moduledoc """
  Callback registry for extending Arca.CLI functionality.

  This module allows other applications to register callbacks for various
  extension points in Arca.CLI without creating circular dependencies.

  ## Extension Points

  The following extension points are available:

  * `:format_output` - Customize the formatting of output in the REPL
  * `:format_help` - Customize the formatting of help text

  ## Usage Example

  To integrate with Arca.CLI's output formatting:

  ```elixir
  # Check if the callbacks system is available
  if Code.ensure_loaded?(Arca.Cli.Callbacks) do
    # Register a callback for format_output
    Arca.Cli.Callbacks.register(:format_output, fn output ->
      # Format the output as needed
      formatted = format_result(output)
      
      # You can return:
      # - A formatted string to process it and continue the chain
      # - {:cont, value} to explicitly pass a value to the next callback
      # - {:halt, result} to stop the chain and use this result
      {:halt, formatted}
    end)
    
    # Register a callback for format_help
    Arca.Cli.Callbacks.register(:format_help, fn help_text ->
      # Format the help text as needed
      formatted_help = format_help_text(help_text)
      
      {:halt, formatted_help}
    end)
  end
  ```

  ## Callback Chain

  Multiple callbacks can be registered for the same event. They are executed 
  in reverse registration order (last registered, first executed). Each callback
  can either return:

  * A raw value - treated as {:cont, value}
  * {:cont, value} - Continue the chain with this value
  * {:halt, result} - Stop the chain and use this result

  This allows for compositional behavior where each formatter can build on the 
  previous one's output or entirely replace the formatting behavior.
  """

  @doc """
  Register a callback function for a specific event.

  ## Parameters

  - `event`: The event name (atom)
  - `callback`: The callback function (function)

  ## Returns

  `:ok`

  ## Examples

      iex> Arca.Cli.Callbacks.register(:format_output, &MyApp.format_output/1)
      :ok
  """
  def register(event, callback) when is_atom(event) and is_function(callback) do
    :arca_cli
    |> Application.get_env(:callbacks, %{})
    |> Map.update(event, [callback], &[callback | &1])
    |> then(&Application.put_env(:arca_cli, :callbacks, &1))

    :ok
  end

  @doc """
  Execute all callbacks for a specific event.

  Callbacks are executed in reverse registration order (last registered, first executed).
  Each callback can return {:halt, result} to stop the chain and use that result,
  or {:cont, value} to pass a value to the next callback.

  ## Parameters

  - `event`: The event name (atom)
  - `initial`: The initial value to pass to the first callback

  ## Returns

  The final result after all callbacks have been executed, or the initial value
  if no callbacks are registered.

  ## Examples

      iex> Arca.Cli.Callbacks.execute(:format_output, "Hello")
      "FORMATTED: Hello"
  """
  def execute(event, initial) do
    :arca_cli
    |> Application.get_env(:callbacks, %{})
    |> Map.get(event, [])
    |> Enum.reduce_while({:cont, initial}, fn callback, {:cont, acc} ->
      case callback.(acc) do
        {:halt, result} -> {:halt, result}
        {:cont, value} -> {:cont, {:cont, value}}
        other -> {:cont, {:cont, other}}
      end
    end)
    |> case do
      {:cont, value} -> value
      result -> result
    end
  end

  @doc """
  Check if any callbacks are registered for a specific event.

  ## Parameters

  - `event`: The event name (atom)

  ## Returns

  `true` if callbacks are registered, `false` otherwise

  ## Examples

      iex> Arca.Cli.Callbacks.has_callbacks?(:format_output)
      true
  """
  def has_callbacks?(event) do
    :arca_cli
    |> Application.get_env(:callbacks, %{})
    |> Map.get(event, [])
    |> Enum.empty?()
    |> Kernel.not()
  end
end
