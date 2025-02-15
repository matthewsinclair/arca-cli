defmodule Arca.CLI.Commands.GetCommand do
  @moduledoc """
  Arca CLI command to get a property from settings.
  """
  alias Arca.CLI
  use Arca.CLI.Command.BaseCommand

  config :get,
      name: "get",
      about: "Get the value of a setting.",
      args: [
        id: [
          value_name: "SETTING_ID",
          help: "Setting id",
          required: true,
          parser: :string
        ]
      ]

  @doc """
  Get a settings value from settings by its id (with dot notation)
  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(args, _settings, _optimus) do
    case CLI.get_setting(args.args.id) do
      {:error, error} -> error.message
      value -> value
    end
  rescue
    error in RuntimeError -> error.message
  end
end
