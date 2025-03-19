defmodule Arca.Cli.Repl.FormatterTest do
  use ExUnit.Case, async: false

  alias Arca.Cli.Callbacks

  # Reset callbacks before and after each test
  setup do
    original_callbacks = Application.get_env(:arca_cli, :callbacks, %{})
    Application.put_env(:arca_cli, :callbacks, %{})

    on_exit(fn ->
      Application.put_env(:arca_cli, :callbacks, original_callbacks)
    end)

    :ok
  end

  describe "format_output callbacks" do
    test "uses callbacks when available" do
      # Register a test formatter callback
      Callbacks.register(:format_output, fn output ->
        "FORMATTED: #{output}"
      end)

      result = Callbacks.execute(:format_output, "test output")
      assert result == "FORMATTED: test output"
    end

    test "multiple callbacks are executed in order" do
      Callbacks.register(:format_output, fn output ->
        "#{output} - FIRST FORMATTER"
      end)

      Callbacks.register(:format_output, fn output ->
        "#{output} - SECOND FORMATTER"
      end)

      result = Callbacks.execute(:format_output, "test output")
      assert result == "test output - SECOND FORMATTER - FIRST FORMATTER"
    end

    test "callback can halt the chain" do
      Callbacks.register(:format_output, fn _output ->
        "This will never be reached"
      end)

      Callbacks.register(:format_output, fn output ->
        {:halt, "HALTED: #{output}"}
      end)

      result = Callbacks.execute(:format_output, "test output")
      assert result == "HALTED: test output"
      refute result =~ "never be reached"
    end

    test "behaves correctly when no callbacks are registered" do
      result = Callbacks.execute(:format_output, "test output")
      assert result == "test output"
    end
  end
end
