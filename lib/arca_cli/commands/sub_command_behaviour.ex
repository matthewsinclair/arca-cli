defmodule Arca.Cli.Command.SubCommandBehaviour do
  @moduledoc """
  `Arca.Cli.Command.SubCommandBehaviour`s specify all of the config info needed to assemble a sub command into something coherent that can be processed by the CLI setup routine.
  """
  @type args :: Any

  @doc """
  Return a list of the commands that the sub-command can handle.
  """
  @callback sub_commands() :: any()
end
