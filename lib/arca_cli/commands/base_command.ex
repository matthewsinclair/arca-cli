defmodule Arca.CLI.Command.BaseCommand do
  @moduledoc """
  Use an `Arca.CLI.Command.BaseCommand` to quickly and easily build a new CLI command.
  """
  require Logger

  @doc """
  Implement base functionality for a Command.
  """
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [config: 2]

      alias Arca.CLI.Command.BaseCommand
      import Arca.CLI.Utils
      require Logger
      @behaviour Arca.CLI.Command.CommandBehaviour

      Module.register_attribute(__MODULE__, :cmdcfg, accumulate: false)

      @doc """
      Note: Early definition of the function in Command macro to account for default values.
      """
      @impl Arca.CLI.Command.CommandBehaviour
      def handle(_args \\ nil, _settings \\ nil, _optimus \\ nil)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro config(cmd, opts) do
    quote do
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
      @impl Arca.CLI.Command.CommandBehaviour
      def config() do
        @cmdcfg
      end

      @doc """
      Default handler for the command.
      """
      @impl Arca.CLI.Command.CommandBehaviour
      def handle(_args, _settings, _optimus) do
        this_function_is_not_implemented()
        { :error, :not_implemented }
      end
    end
  end
end
