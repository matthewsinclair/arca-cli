defmodule Arca.Cli.Commands.AboutCommand do
  @moduledoc """
  Arca CLI command to display about info.
  """
  use Arca.Cli.Command.BaseCommand

  config :about,
    name: "about",
    about: "Info about the command line interface."

  @doc """
  Display about info for the core CLI.
  """
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(args, settings, _optimus) do
    Arca.Cli.intro(args, settings) |> put_lines()
  end
end
