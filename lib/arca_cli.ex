defmodule Arca.CLI do
  @moduledoc """
  Documentation for `Arca.CLI`.
  """

  use Application
  require Logger
  require OK
  use OK.Pipe
  import Arca.CLI.Utils
  alias Arca.Config.Cfg
  alias Arca.CLI.Configurator.Coordinator

  @doc """
  Handle Application functionality to start the Arca.CLI subsystem.
  """
  @impl true
  def start(_type, _args) do
    # Logger.info("#{__MODULE__}.start: #{inspect(args)}")

    children = [
      {Arca.CLI.HistorySupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Arca.CLI]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Entry point for command line parsing.
  """
  def main(argv) do
    Application.put_env(:elixir, :ansi_enabled, true)
    unless length(argv) != 0, do: intro() |> put_lines

    settings = load_settings() |> with_default(%{})
    optimus = optimus_config()

    Optimus.parse(optimus, argv)
    |> handle_args(settings, optimus)
    |> filter_blank_lines
    |> put_lines
  end

  @doc """
  Provide an Optimus config to drive the CLI.
  """
  def optimus_config do
    configurators()
    |> Coordinator.setup()
  end

  @doc """
  Grab the list of Configurators specified in config to :arca_cli.
  """
  def configurators() do
    Application.fetch_env!(:arca_cli, :configurators)
  end

  @doc """
  Grab the list of Commands that have been specified in config to :arca_cli.
  """
  def commands() do
    configurators()
    |> Enum.flat_map(& &1.commands())
  end

  @doc """
  Return the command handlder for the specfied command. Look in commands if provided, and if not, default to the list of commands provided by the commands() function.
  """
  def handler_for_command(cmd, commands \\ commands()) do
    command_module_name = "#{Atom.to_string(cmd) |> String.capitalize()}Command"

    commands
    |> Enum.find(fn module ->
      module_name_parts = Module.split(module)
      List.last(module_name_parts) == command_module_name
    end)
  end

  @doc """
  Handle the command line arguments.
  """
  def handle_args(args, settings, optimus) do
    case args do
      {:ok, [subcmd], args} ->
        handle_subcommand(subcmd, args, settings, optimus)

      {:ok, msg} when is_binary(msg) ->
        msg

      {:ok, %Optimus.ParseResult{unknown: []}} ->
        # When called with no params, just show usage
        Optimus.Help.help(optimus, [], 80) |> Enum.drop(2)

      {:ok, %Optimus.ParseResult{unknown: errors}} ->
        # When called with an unknown param(s), show an error
        handle_error(["Unknown command:"] ++ errors)

      {:error, cmd, reason} ->
        handle_error(cmd, reason)

      {:error, reason} ->
        handle_error(reason)

      {:help, subcmd} ->
        # Optimus.Help.help puts intro() and contact() on the front of this, so drop it
        Optimus.Help.help(optimus, subcmd, 80) |> Enum.drop(2)

      :help ->
        # Optimus.Help.help puts intro() and contact() on the front of this, so drop it
        Optimus.Help.help(optimus, [], 80) |> Enum.drop(2)

      _other ->
        # Optimus.Help.help puts intro() and contact() on the front of this, so drop it
        Optimus.Help.help(optimus, [], 80) |> Enum.drop(2)
    end
  end

  @doc """
  Dispatch to the appropriate subcommand, if we can find one.
  """
  def handle_subcommand(cmd, args, settings, optimus) do
    # Logger.info("#{__MODULE__}.handle_subcommand: #{inspect(cmd)}, #{inspect(args)}")

    case handler_for_command(cmd) do
      nil ->
        handle_error(cmd, "unknown command: #{cmd}")

      handler ->
        handler.handle(args, settings, optimus)
    end
  end

  @doc """
  Handle an error nicely.
  """
  def handle_error(cmd, reason) when is_atom(cmd) do
    handle_error([Atom.to_string(cmd)], [inspect(reason)])
  end

  def handle_error(cmd, reason) do
    ("error: " <> Enum.join(cmd, " ") <> ": " <> Enum.join(reason, " "))
    |> String.trim()
  end

  def handle_error(%RuntimeError{message: message}), do: handle_error(message)

  def handle_error(reasons) when is_list(reasons) do
    ("error: " <> Enum.join(reasons, " "))
    |> String.trim()
  end

  def handle_error(reason) when is_binary(reason) do
    "error: #{reason}"
    |> String.trim()
  end

  @doc """
  Load settings from JSON config file.
  """
  def load_settings() do
    case Cfg.load() do
      {:ok, settings} -> settings
      {:error, _reason} -> %{}
    end
  end

  @doc """
  Get a setting by its id (and with dot notation).
  """
  def get_setting(id) do
    case Cfg.get(id) do
      {:ok, value} -> value
      {:error, reason} -> raise "Error getting setting: #{reason}"
    end
  end

  @doc """
  Save settings to JSON config file.
  """
  def save_settings(new_settings) do
    {:ok, current_settings} = Cfg.load()
    updated_settings = Map.merge(current_settings, new_settings)

    case Cfg.put(:settings, updated_settings) do
      {:ok, _} -> :ok
      {:error, reason} -> raise "Error saving settings: #{reason}"
    end
  end

  @doc """
  Print an about message
  """
  def intro(args \\ [], settings \\ nil)

  def intro(_args, _settings) do
    about() <> "\n" <> description() <> "\n" <> url() <> "\n" <> name() <> " " <> version()
  end

  # Accessors for string constants set via config
  def about do
    Application.fetch_env!(:arca_cli, :about)
  end

  def url do
    Application.fetch_env!(:arca_cli, :url)
  end

  def name do
    Application.fetch_env!(:arca_cli, :name)
  end

  def description do
    Application.fetch_env!(:arca_cli, :description)
  end

  def version do
    Application.fetch_env!(:arca_cli, :version)
  end

  def author do
    Application.fetch_env!(:arca_cli, :author)
  end

  def prompt_symbol do
    Application.fetch_env!(:arca_cli, :prompt_symbol)
  end
end
