defmodule Arca.Cli.ExampleFormatter do
  @moduledoc """
  An example formatter implementation to demonstrate using the Arca.Cli.Callbacks system.
  
  This formatter adds ANSI colors to different types of output in the REPL.
  It's intended as a demonstration only and not for production use.
  """
  
  alias Arca.Cli.Callbacks
  alias Arca.Cli.Utils
  
  @doc """
  Register this formatter with the callback system.
  
  Call this function when your application starts to enable colorized output
  in the Arca.Cli REPL.
  
  ## Example
  
      iex> Arca.Cli.ExampleFormatter.register()
      :ok
  """
  def register do
    if Code.ensure_loaded?(Callbacks) do
      Callbacks.register(:format_output, &format_output/1)
      :ok
    else
      {:error, :callbacks_not_available}
    end
  end
  
  @doc """
  Format the output with ANSI colors based on content type.
  
  This formatter will:
  - Colorize strings in green
  - Colorize numbers in cyan
  - Colorize lists in yellow
  - Colorize maps and other structures in magenta
  - Colorize errors in red
  
  It's intended as a simple example of how to implement a formatter.
  """
  def format_output(output) do
    formatted =
      case Utils.type_of(output) do
        "string" -> 
          IO.ANSI.green() <> output <> IO.ANSI.reset()
        
        "number" -> 
          IO.ANSI.cyan() <> to_string(output) <> IO.ANSI.reset()
        
        "list" -> 
          IO.ANSI.yellow() <> inspect(output, pretty: true) <> IO.ANSI.reset()
        
        "map" -> 
          IO.ANSI.magenta() <> inspect(output, pretty: true) <> IO.ANSI.reset()
        
        "error" -> 
          IO.ANSI.red() <> "Error: " <> inspect(output) <> IO.ANSI.reset()
        
        _other -> 
          # For any other type, just return the string representation
          inspect(output, pretty: true)
      end
      
    # Return the formatted output and continue the chain
    # This allows other formatters to further process our output
    {:cont, formatted}
  end
end