defmodule Arca.CLI.Configurator.ConfiguratorBehaviour do
  @moduledoc """
  Documentation for `Arca.CLI.Configurator.ConfiguratorBehaviour`.
  """

  alias Optimus

  @doc """
  Returns a list of `Arca.CLI.Command.CommandBehaviour`s that will be used by the CLI for setup.
  """
  @callback commands() :: list()

  @doc """
  Run setup across the provided commands and return an Optimis configuration for the CLI.
  """
  @callback setup() :: Optimus.t()

  @doc """
  Provide the name of the app that the CLI is running in (or nil if not needed).
  """
  @callback name() :: String.t() | nil

  @doc """
  Provide an author for the app that the CLI is running in (or nil if not needed).
  """
  @callback author() :: String.t() | nil

  @doc """
  Provide an about message for the app that the CLI is running in (or nil if not needed).
  """
  @callback about() :: String.t()

  @doc """
  Provide a short description of the app that the CLI is running in (or nil if not needed)
  """
  @callback description() :: String.t() | nil

  @doc """
  Provide a the version numver of the app that the CLI is running in (or nil if not needed)
  """
  @callback version() :: String.t() | nil

  @doc """
  Allow (or dissallow) unknown args.
  """
  @callback allow_unknown_args() :: boolean()

  @doc """
  Parse (or ignore) double-dashes.
  """
  @callback parse_double_dash() :: boolean()

  @doc """
  Create the basic structure of the Optimus config.
  """
  @callback create_base_config() :: list()
end
