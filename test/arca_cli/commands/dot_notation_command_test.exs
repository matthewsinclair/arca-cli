defmodule ArcaCliDotNotationCommandTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Arca.CLI
  # alias Arca.CLI.Command.BaseCommand

  describe "Dot notation commands" do
    test "handler_for_command works with dot notation" do
      {result_type, cmd, handler} = CLI.handler_for_command(:"sys.info")
      assert result_type == :ok
      assert cmd == :"sys.info"
      assert handler == Arca.CLI.Commands.SysInfoCommand
    end

    test "can execute dot notation command" do
      output = capture_io(fn ->
        CLI.main(["sys.info"])
      end)

      assert output =~ "System Information:"
      assert output =~ "Elixir Version:"
      assert output =~ "OTP Version:"
      assert output =~ "System Architecture:"
    end

    test "dot notation appears in help" do
      output = capture_io(fn ->
        CLI.main(["--help"])
      end)

      assert output =~ "sys.info"
      assert output =~ "Display system information."
    end
  end
end
