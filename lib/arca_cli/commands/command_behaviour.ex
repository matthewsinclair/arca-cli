defmodule Arca.CLI.Command.CommandBehaviour do
  @moduledoc """
  `Arca.CLI.Command.CommandBehaviour`s specify all of the config info needed to assemble the command into something coherent that can be processed by the CLI setup routine.
  """

  alias Optimus

  @type t :: [{:name, String.t()} | {:about, String.t()}]

  @type args :: Any
  @type settings :: map
  @type optimus :: term

  @doc """
  Returns Optimus-compatible config that can be used by the configurator to assemble a coherent configuration
  """
  @callback config() :: list()

  @doc """
  Perform the command's logic
  """
  @callback handle(args, settings, optimus) :: any()
end
