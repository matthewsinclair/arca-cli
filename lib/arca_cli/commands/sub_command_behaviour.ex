defmodule Arca.Cli.Command.SubCommandBehaviour do
  @moduledoc """
  `Arca.Cli.Command.SubCommandBehaviour` specifies the interface for commands that handle subcommands.

  Subcommands allow for hierarchical command structures where a main command (like 'settings')
  can have multiple subcommands (like 'settings.get', 'settings.set', etc.).

  Modules implementing this behaviour must also implement `Arca.Cli.Command.CommandBehaviour`.
  """

  @typedoc """
  Arguments passed to subcommand handlers.
  """
  @type args :: map() | Optimus.ParseResult.t() | nil

  @typedoc """
  A list of command modules available as subcommands.
  """
  @type sub_command_list :: [module()]

  @typedoc """
  Result type for subcommand operations.
  """
  @type result(t) :: {:ok, t} | {:error, error_type(), String.t()}

  @typedoc """
  Possible error types from subcommand operations.
  """
  @type error_type ::
          :command_not_found
          | :invalid_command
          | :parsing_error
          | :dispatch_error

  @doc """
  Return a list of the command modules that the subcommand can handle.

  This function should return a list of modules that implement the 
  `Arca.Cli.Command.CommandBehaviour` and can be handled by this subcommand.
  """
  @callback sub_commands() :: sub_command_list()
end
