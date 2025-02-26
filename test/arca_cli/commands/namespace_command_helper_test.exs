defmodule ArcaCliNamespaceCommandHelperTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Arca.CLI

  # Define a test namespace module using our helper
  # We need to ensure the commands are registered with the application
  defmodule TestNamespace do
    use Arca.CLI.Commands.NamespaceCommandHelper
    
    namespace_command :test1, "Test command 1" do
      "Output from test1"
    end
    
    namespace_command :test2, "Test command 2" do
      "Output from test2"
    end
  end
  
  # Need to register our test commands with the application for testing
  setup do
    old_configurators = Application.get_env(:arca_cli, :configurators, [])
    
    # Create a test configurator that includes our test commands
    defmodule TestConfigurator do
      @behaviour Arca.CLI.Configurator.ConfiguratorBehaviour
      
      @impl true
      def commands do
        [
          Arca.CLI.Commands.TestTest1Command,
          Arca.CLI.Commands.TestTest2Command
        ]
      end
      
      @impl true
      def create_base_config do
        %{
          name: "test-cli",
          description: "Test CLI",
          version: "0.0.1",
          about: "Test CLI for namespace helper",
          allow_unknown_args: false,
          parse_double_dash: true,
          flags: [],
          args: []
        }
      end
    end
    
    # Update application config to include our test configurator
    Application.put_env(:arca_cli, :configurators, [TestConfigurator | old_configurators])
    
    on_exit(fn ->
      # Restore original configurators
      Application.put_env(:arca_cli, :configurators, old_configurators)
    end)
    
    :ok
  end
  
  describe "Namespace command helper" do
    @tag :skip
    test "generates commands with proper namespaces" do
      # Check for TestTest1Command module existence
      assert Code.ensure_loaded?(Arca.CLI.Commands.TestTest1Command)
      assert Code.ensure_loaded?(Arca.CLI.Commands.TestTest2Command)
      
      # Verify command config
      assert {:"test.test1", _opts} = Arca.CLI.Commands.TestTest1Command.config() |> List.first()
      assert {:"test.test2", _opts} = Arca.CLI.Commands.TestTest2Command.config() |> List.first()
    end
    
    @tag :skip
    test "properly wires up command handling" do
      # Test command execution for first command
      output = capture_io(fn ->
        CLI.main(["test.test1"])
      end)
      
      assert output =~ "Output from test1"
      
      # Test command execution for second command
      output = capture_io(fn ->
        CLI.main(["test.test2"])
      end)
      
      assert output =~ "Output from test2"
    end
    
    @tag :skip
    test "appears in help output" do
      output = capture_io(fn ->
        CLI.main(["--help"])
      end)
      
      assert output =~ "test.test1"
      assert output =~ "Test command 1"
      assert output =~ "test.test2"
      assert output =~ "Test command 2"
    end
  end
end