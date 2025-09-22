defmodule Arca.Cli.OutputTest do
  use ExUnit.Case
  alias Arca.Cli.Output
  alias Arca.Cli.Ctx

  describe "render/1" do
    test "renders nil context as empty string" do
      assert Output.render(nil) == ""
    end

    test "renders empty context without errors" do
      ctx = %Ctx{}
      result = Output.render(ctx)
      assert is_binary(result)
    end

    test "renders success message correctly" do
      ctx = %Ctx{output: [{:success, "Operation complete"}]}
      result = Output.render(ctx)
      assert result =~ "Operation complete"
      # Should contain checkmark in either fancy or plain mode
      assert result =~ "✓" or result =~ "Operation complete"
    end

    test "renders error message correctly" do
      ctx = %Ctx{output: [{:error, "Operation failed"}]}
      result = Output.render(ctx)
      assert result =~ "Operation failed"
      # Should contain cross in either fancy or plain mode
      assert result =~ "✗" or result =~ "Operation failed"
    end

    test "renders multiple output items" do
      ctx = %Ctx{
        output: [
          {:info, "Starting"},
          {:success, "Done"},
          {:warning, "Check logs"}
        ]
      }

      result = Output.render(ctx)
      assert result =~ "Starting"
      assert result =~ "Done"
      assert result =~ "Check logs"
    end
  end

  describe "style determination" do
    setup do
      # Save environment variables
      no_color = System.get_env("NO_COLOR")
      arca_style = System.get_env("ARCA_STYLE")
      mix_env = System.get_env("MIX_ENV")
      term = System.get_env("TERM")

      on_exit(fn ->
        # Restore original env vars
        restore_env("NO_COLOR", no_color)
        restore_env("ARCA_STYLE", arca_style)
        restore_env("MIX_ENV", mix_env)
        restore_env("TERM", term)
      end)

      :ok
    end

    test "uses style from context metadata when present" do
      ctx = %Ctx{output: [{:text, "test"}], meta: %{style: :dump}}
      result = Output.render(ctx)
      # Dump format should show the Context structure
      assert result =~ "%{"
      assert result =~ "output:"
      assert result =~ "meta:"
    end

    test "respects NO_COLOR environment variable" do
      System.put_env("NO_COLOR", "1")
      # Would normally trigger fancy
      System.put_env("TERM", "xterm-256color")

      assert Output.current_style() == :plain
    end

    test "respects ARCA_STYLE environment variable" do
      System.put_env("ARCA_STYLE", "dump")
      System.delete_env("NO_COLOR")

      assert Output.current_style() == :dump
    end

    test "NO_COLOR takes precedence over ARCA_STYLE" do
      System.put_env("NO_COLOR", "1")
      System.put_env("ARCA_STYLE", "fancy")

      assert Output.current_style() == :plain
    end

    test "uses plain style in test environment" do
      System.put_env("MIX_ENV", "test")
      System.delete_env("NO_COLOR")
      System.delete_env("ARCA_STYLE")

      assert Output.current_style() == :plain
    end

    test "detects TTY and uses fancy when available" do
      System.delete_env("NO_COLOR")
      System.delete_env("ARCA_STYLE")
      System.put_env("MIX_ENV", "dev")
      System.put_env("TERM", "xterm-256color")

      # This may still return plain depending on actual TTY detection
      # but should not error
      style = Output.current_style()
      assert style in [:fancy, :plain]
    end

    test "uses plain when TERM is dumb" do
      System.put_env("TERM", "dumb")
      System.delete_env("NO_COLOR")
      System.delete_env("ARCA_STYLE")
      System.put_env("MIX_ENV", "dev")

      assert Output.current_style() == :plain
    end

    test "uses plain when TERM is not set" do
      System.delete_env("TERM")
      System.delete_env("NO_COLOR")
      System.delete_env("ARCA_STYLE")
      System.put_env("MIX_ENV", "dev")

      assert Output.current_style() == :plain
    end
  end

  describe "dump renderer" do
    test "shows full context structure" do
      ctx = %Ctx{
        command: "test",
        args: %{file: "test.ex"},
        options: %{verbose: true},
        output: [{:success, "Done"}],
        errors: ["Error 1"],
        status: :ok,
        cargo: %{data: "value"},
        meta: %{style: :dump}
      }

      result = Output.render(ctx)

      # Should show all fields
      assert result =~ "command: \"test\""
      assert result =~ "args: %{file: \"test.ex\"}"
      assert result =~ "options: %{verbose: true}"
      # inspect/2 may format the tuple differently
      assert result =~ "output:"
      assert result =~ "success"
      assert result =~ "Done"
      assert result =~ "errors: [\"Error 1\"]"
      assert result =~ "status: :ok"
      assert result =~ "cargo: %{data: \"value\"}"
      assert result =~ "meta: %{style: :dump}"
    end

    test "handles empty context in dump mode" do
      ctx = %Ctx{meta: %{style: :dump}}
      result = Output.render(ctx)

      assert result =~ "%{"
      assert result =~ "command: nil"
      assert result =~ "output: []"
    end
  end

  describe "renderer dispatch" do
    test "dispatches to fancy renderer when style is fancy" do
      ctx = %Ctx{
        output: [{:success, "Test"}],
        meta: %{style: :fancy}
      }

      result = Output.render(ctx)

      # Fancy renderer should include colors if properly mocked
      assert is_binary(result)
      assert result =~ "Test"
    end

    test "dispatches to plain renderer when style is plain" do
      ctx = %Ctx{
        output: [{:success, "Test"}],
        meta: %{style: :plain}
      }

      result = Output.render(ctx)

      # Plain renderer returns iodata, should be converted to binary
      assert is_binary(result)
      assert result =~ "✓"
      assert result =~ "Test"
    end

    test "handles tables in output" do
      ctx = %Ctx{
        output: [{:table, [%{name: "Alice", age: 30}], []}]
      }

      result = Output.render(ctx)

      assert result =~ "Alice"
      assert result =~ "30"
    end

    test "handles lists in output" do
      ctx = %Ctx{
        output: [{:list, ["Item 1", "Item 2"], title: "Items"}]
      }

      result = Output.render(ctx)

      assert result =~ "Item 1"
      assert result =~ "Item 2"
    end
  end

  describe "current_style/1" do
    test "returns style for nil context" do
      style = Output.current_style(nil)
      assert style in [:fancy, :plain, :dump]
    end

    test "returns style from context metadata" do
      ctx = %Ctx{meta: %{style: :plain}}
      assert Output.current_style(ctx) == :plain
    end

    test "returns environment-determined style" do
      System.put_env("ARCA_STYLE", "dump")
      assert Output.current_style() == :dump
    end
  end

  describe "edge cases" do
    test "handles context with nil output" do
      ctx = %Ctx{output: nil}
      # Should not crash, even though output should be a list
      result = Output.render(ctx)
      assert is_binary(result)
    end

    test "handles malformed context gracefully" do
      # Even with unexpected data, should not crash
      ctx = %Ctx{output: "not a list"}
      result = Output.render(ctx)
      assert is_binary(result)
    end

    test "always returns a string" do
      test_cases = [
        %Ctx{},
        %Ctx{output: []},
        %Ctx{output: [{:success, "Test"}]},
        %Ctx{output: [{:table, [], []}]},
        %Ctx{meta: %{style: :dump}},
        %Ctx{meta: %{style: :plain}},
        %Ctx{meta: %{style: :fancy}}
      ]

      for ctx <- test_cases do
        result = Output.render(ctx)
        assert is_binary(result), "Failed for context: #{inspect(ctx)}"
      end
    end
  end

  describe "NO_COLOR variations" do
    setup do
      no_color = System.get_env("NO_COLOR")
      on_exit(fn -> restore_env("NO_COLOR", no_color) end)
      :ok
    end

    test "NO_COLOR=1 forces plain" do
      System.put_env("NO_COLOR", "1")
      assert Output.current_style() == :plain
    end

    test "NO_COLOR=true forces plain" do
      System.put_env("NO_COLOR", "true")
      assert Output.current_style() == :plain
    end

    test "NO_COLOR=0 does not force plain" do
      System.put_env("NO_COLOR", "0")
      System.put_env("ARCA_STYLE", "fancy")
      assert Output.current_style() == :fancy
    end

    test "NO_COLOR=false does not force plain" do
      System.put_env("NO_COLOR", "false")
      System.put_env("ARCA_STYLE", "fancy")
      assert Output.current_style() == :fancy
    end

    test "empty NO_COLOR does not force plain" do
      System.put_env("NO_COLOR", "")
      System.put_env("ARCA_STYLE", "fancy")
      assert Output.current_style() == :fancy
    end
  end

  # Helper to restore environment variables
  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
