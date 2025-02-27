defmodule Arca.Cli.Commands.SysInfoCommand do
  @moduledoc """
  Command to display system information.
  This is a test command for dot notation (sys.info).
  """
  use Arca.Cli.Command.BaseCommand

  config :"sys.info",
    name: "sys.info",
    about: "Display system information."

  @impl Arca.Cli.Command.CommandBehaviour
  def handle(_args, _settings, _optimus) do
    """
    System Information:
    Elixir Version: #{System.version()}
    OTP Version: #{:erlang.system_info(:otp_release)}
    System Architecture: #{:erlang.system_info(:system_architecture)}
    """
  end
end
