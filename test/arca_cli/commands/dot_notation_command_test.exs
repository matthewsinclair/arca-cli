defmodule ArcaCliDotNotationCommandTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Arca.Cli
  # alias Arca.Cli.Command.BaseCommand

  describe "Dot notation commands" do
    test "handler_for_command works with dot notation" do
      {result_type, cmd, handler} = Cli.handler_for_command(:"sys.info")
      assert result_type == :ok
      assert cmd == :"sys.info"
      assert handler == Arca.Cli.Commands.SysInfoCommand
    end

    test "can execute dot notation command" do
      output = capture_io(fn ->
        Cli.main(["sys.info"])
      end)

      assert output =~ "System Information:"
      assert output =~ "Elixir Version:"
      assert output =~ "OTP Version:"
      assert output =~ "System Architecture:"
    end

    test "dot notation appears in help" do
      output = capture_io(fn ->
        Cli.main(["--help"])
      end)

      assert output =~ "sys.info"
      assert output =~ "Display system information."
    end
  end
end
