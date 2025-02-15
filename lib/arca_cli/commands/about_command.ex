defmodule Arca.CLI.Commands.AboutCommand do
  @moduledoc """
  Arca CLI command to display about info.
  """
  use Arca.CLI.Command.BaseCommand

  config :about,
    name: "about",
    about: "Info about the command line interface."

  @doc """
  Display about info for the core CLI.
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(args, settings, _optimus) do
    Arca.CLI.intro(args, settings) |> put_lines()
  end
end
