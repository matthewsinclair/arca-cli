defmodule Arca.Cli.Commands.SettingsGetCommand do
  @moduledoc """
  Arca CLI command to get a property from settings.
  """
  alias Arca.Cli
  use Arca.Cli.Command.BaseCommand

  config :"settings.get",
    name: "settings.get",
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
  @impl Arca.Cli.Command.CommandBehaviour
  def handle(args, _settings, _optimus) do
    case Cli.get_setting(args.args.id) do
      {:error, message} when is_binary(message) -> message
      value -> value
    end
  rescue
    error in RuntimeError -> error.message
  end
end