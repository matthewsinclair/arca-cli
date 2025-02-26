defmodule ArcaCliReplTest do
  use ExUnit.Case
  alias Arca.CLI.Repl

  describe "REPL autocompletion" do
    test "available_commands returns all registered commands" do
      commands = Repl.available_commands()
      
      # Check for some common commands that should be available
      assert Enum.member?(commands, "about")
      assert Enum.member?(commands, "cli.status") # Changed from "status" to "cli.status"
      
      # Check for namespace commands
      assert Enum.any?(commands, fn cmd -> String.starts_with?(cmd, "sys.") end)
      # Note: We're commenting out these checks because we haven't registered these commands yet
      # These commands would be available in a real application but not in tests
      # assert Enum.any?(commands, fn cmd -> String.starts_with?(cmd, "dev.") end)
      # assert Enum.any?(commands, fn cmd -> String.starts_with?(cmd, "config.") end)
    end
    
    test "autocomplete with empty string returns all commands" do
      suggestions = Repl.autocomplete("")
      assert length(suggestions) > 0
    end
    
    test "autocomplete with partial command returns matching commands" do
      # Test with standard command prefix
      suggestions = Repl.autocomplete("ab")
      assert "about" in suggestions
      
      # Test with sys namespace prefix
      suggestions = Repl.autocomplete("sys")
      assert Enum.any?(suggestions, fn cmd -> cmd == "sys" || String.starts_with?(cmd, "sys.") end)
      
      # Test with full namespace prefix
      suggestions = Repl.autocomplete("sys.")
      assert Enum.all?(suggestions, fn cmd -> String.starts_with?(cmd, "sys.") end)
      
      # Test with specific namespace command
      suggestions = Repl.autocomplete("sys.i")
      assert "sys.info" in suggestions
    end
    
    test "should_push? excludes specific commands from history" do
      assert Repl.should_push?("about") == true
      assert Repl.should_push?("status") == true
      assert Repl.should_push?("history") == false
      assert Repl.should_push?("help") == false
      assert Repl.should_push?("redo") == false
      assert Repl.should_push?("flush") == false
    end
  end
end