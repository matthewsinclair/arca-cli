defmodule Arca.Cli.Commands.CliDebugCommand do
  @moduledoc """
  Command to show or toggle debug mode for detailed error information.

  This command allows users to:
  - View the current debug mode status: `cli cli.debug`
  - Enable debug mode: `cli cli.debug on`
  - Disable debug mode: `cli cli.debug off`

  When debug mode is enabled, error messages will include detailed information
  such as stack traces and error context, which is helpful for troubleshooting.

  ## Examples

      $ cli cli.debug
      Debug mode is currently OFF

      $ cli cli.debug on
      Debug mode is now ON

      $ cli cli.debug off
      Debug mode is now OFF
  """
  use Arca.Cli.Command.BaseCommand

  config :"cli.debug",
    name: "cli.debug",
    about: "Show or toggle debug mode for detailed error information",
    args: [
      toggle: [
        value_name: "on|off",
        help: "Turn debug mode on or off",
        required: false
      ]
    ]

  @impl true
  def handle(args, _settings, _optimus) do
    toggle = args.args.toggle

    # Get current debug mode setting
    current =
      case Arca.Cli.get_setting("debug_mode") do
        {:ok, value} -> value
        _ -> Application.get_env(:arca_cli, :debug_mode, false)
      end

    case toggle do
      nil ->
        "Debug mode is currently #{if current, do: "ON", else: "OFF"}"

      "on" ->
        # Update both Application env (for current process) and persistent settings
        Application.put_env(:arca_cli, :debug_mode, true)
        save_debug_setting(true)
        "Debug mode is now ON"

      "off" ->
        # Update both Application env (for current process) and persistent settings
        Application.put_env(:arca_cli, :debug_mode, false)
        save_debug_setting(false)
        "Debug mode is now OFF"

      _ ->
        {:error, :invalid_argument, "Invalid value '#{toggle}'. Use 'on' or 'off'."}
    end
  end

  # Save debug setting to persistent storage
  defp save_debug_setting(value) do
    # Try to save with Arca.Config mechanism if available
    case Arca.Cli.save_settings(%{"debug_mode" => value}) do
      {:ok, _} -> :ok
      _ -> :error
    end
  end
end
