defmodule Arca.Cli.Command.CommandBehaviour do
  @moduledoc """
  `Arca.Cli.Command.CommandBehaviour` specifies all of the configuration information 
  needed to assemble a command into something coherent that can be processed by the CLI setup routine.

  This behaviour is implemented by all command modules in the system and provides a consistent
  interface for configuration and command handling.
  """

  alias Optimus

  @typedoc """
  Represents the command configuration with name, description, and options.
  """
  @type t :: [
    {:name, String.t()} | 
    {:about, String.t()} | 
    {:show_help_on_empty, boolean()}
  ]

  @typedoc """
  Arguments passed to the command handler.
  Can be a map of parsed arguments, or a specific parsed structure from Optimus.
  """
  @type args :: map() | Optimus.ParseResult.t() | nil

  @typedoc """
  Application settings loaded from configuration.
  """
  @type settings :: map()

  @typedoc """
  Optimus instance used for parsing command-line arguments.
  """
  @type optimus :: Optimus.t()

  @typedoc """
  Return value for command handlers.
  """
  @type handle_result :: String.t() | [String.t()] | {:ok, any()} | {:error, any()} | :help | {:help, atom()}

  @doc """
  Returns Optimus-compatible config that can be used by the configurator to assemble a coherent configuration.

  This function should return a keyword list that defines the command's structure,
  including its name, description, and any arguments or options it accepts.
  """
  @callback config() :: list()

  @doc """
  Perform the command's logic.

  This function is called when the command is invoked and is responsible for executing
  the command's functionality. It receives parsed arguments, application settings,
  and the Optimus instance.

  It should return either:
  - A string or list of strings to be displayed to the user
  - {:ok, result} tuple for successful execution
  - {:error, reason} tuple for failed execution
  """
  @callback handle(args(), settings(), optimus()) :: handle_result()
end
