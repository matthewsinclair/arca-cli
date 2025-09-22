defmodule Arca.Cli.Callbacks.FormatOutputPolymorphicTest do
  use ExUnit.Case, async: false
  alias Arca.Cli.{Ctx, Callbacks}

  describe "format_output callbacks with polymorphic support" do
    setup do
      # Save existing callbacks
      existing_callbacks = Application.get_env(:arca_cli, :callbacks, %{})

      # Clear callbacks for test
      Application.put_env(:arca_cli, :callbacks, %{})

      on_exit(fn ->
        # Restore original callbacks
        Application.put_env(:arca_cli, :callbacks, existing_callbacks)
      end)

      :ok
    end

    test "handles string input (legacy)" do
      # Register a string formatter
      Callbacks.register(:format_output, &string_formatter/1)

      result = Callbacks.execute(:format_output, "test")
      assert result == "[LEGACY] test"
    end

    test "handles Context input (modern)" do
      # Register a context formatter
      Callbacks.register(:format_output, &context_formatter/1)

      ctx = %Ctx{output: [{:text, "test"}]}
      result = Callbacks.execute(:format_output, ctx)

      assert %Ctx{meta: %{formatted: true}} = result
    end

    test "string formatter ignores Context input" do
      # Register a string-only formatter
      Callbacks.register(:format_output, &string_formatter/1)

      ctx = %Ctx{output: [{:text, "test"}]}
      result = Callbacks.execute(:format_output, ctx)

      # Context should pass through unchanged
      assert result == ctx
    end

    test "context formatter ignores string input" do
      # Register a context-only formatter
      Callbacks.register(:format_output, &context_formatter/1)

      result = Callbacks.execute(:format_output, "test string")

      # String should pass through unchanged
      assert result == "test string"
    end

    test "chains multiple callbacks of mixed types" do
      # Register multiple formatters in order
      Callbacks.register(:format_output, &string_formatter/1)
      Callbacks.register(:format_output, &universal_formatter/1)
      Callbacks.register(:format_output, &context_formatter/1)

      # Test with string - callbacks are applied in registration order
      string_result = Callbacks.execute(:format_output, "test")
      assert string_result == "[LEGACY] [UNIVERSAL] test"

      # Test with Context - context_formatter runs after universal_formatter
      ctx = %Ctx{output: [{:text, "test"}]}
      ctx_result = Callbacks.execute(:format_output, ctx)
      assert %Ctx{meta: %{formatted: true, universal: true}} = ctx_result
    end

    test "handles callback errors gracefully" do
      # Register a faulty callback
      Callbacks.register(:format_output, fn _data ->
        raise "Intentional error"
      end)

      # Should return data unchanged when callback fails
      result = Callbacks.execute(:format_output, "test")
      assert result == "test"

      ctx = %Ctx{output: []}
      ctx_result = Callbacks.execute(:format_output, ctx)
      assert ctx_result == ctx
    end

    test "empty callback list returns data unchanged" do
      # No callbacks registered
      string_result = Callbacks.execute(:format_output, "test")
      assert string_result == "test"

      ctx = %Ctx{output: []}
      ctx_result = Callbacks.execute(:format_output, ctx)
      assert ctx_result == ctx
    end

    test "handles unexpected data types" do
      Callbacks.register(:format_output, &universal_formatter/1)

      # Test with number
      assert Callbacks.execute(:format_output, 42) == 42

      # Test with atom
      assert Callbacks.execute(:format_output, :atom) == :atom

      # Test with list
      assert Callbacks.execute(:format_output, [1, 2, 3]) == [1, 2, 3]
    end

    test "real-world example with PolymorphicFormatter" do
      Callbacks.register(:format_output, &PolymorphicFormatter.format/1)
      Callbacks.register(:format_output, &PolymorphicFormatter.add_timestamp/1)

      # Test with string
      string_result = Callbacks.execute(:format_output, "Hello")
      assert string_result =~ "[FORMATTED] Hello"
      # Has timestamp
      assert string_result =~ "["

      # Test with Context
      ctx = %Ctx{output: [{:text, "test"}]}
      ctx_result = Callbacks.execute(:format_output, ctx)

      assert %Ctx{
               output: output,
               meta: %{formatted_at: _}
             } = ctx_result

      # Should have added info messages
      assert Enum.any?(output, fn
               {:info, "Formatted by callback"} -> true
               _ -> false
             end)

      assert Enum.any?(output, fn
               {:info, msg} -> String.starts_with?(msg, "Generated at:")
               _ -> false
             end)
    end
  end

  describe "integration with Output module" do
    setup do
      # Save existing callbacks
      existing_callbacks = Application.get_env(:arca_cli, :callbacks, %{})

      # Clear callbacks for test
      Application.put_env(:arca_cli, :callbacks, %{})

      on_exit(fn ->
        # Restore original callbacks
        Application.put_env(:arca_cli, :callbacks, existing_callbacks)
      end)

      :ok
    end

    test "Output.apply_format_callbacks/1 works with no callbacks" do
      result = Arca.Cli.Output.apply_format_callbacks("test")
      assert result == "test"

      ctx = %Ctx{}
      ctx_result = Arca.Cli.Output.apply_format_callbacks(ctx)
      assert ctx_result == ctx
    end

    test "Output.apply_format_callbacks/1 applies registered callbacks" do
      Callbacks.register(:format_output, &string_formatter/1)

      result = Arca.Cli.Output.apply_format_callbacks("test")
      assert result == "[LEGACY] test"
    end

    test "Output.render/1 applies callbacks before rendering" do
      # Register a callback that adds output
      Callbacks.register(:format_output, fn
        %Ctx{} = ctx ->
          Ctx.add_output(ctx, {:info, "Added by callback"})

        other ->
          other
      end)

      ctx = %Ctx{output: [{:text, "original"}]}
      result = Arca.Cli.Output.render(ctx)

      assert result =~ "original"
      assert result =~ "Added by callback"
    end
  end

  # Test helper formatters with pattern matching

  defp string_formatter(str) when is_binary(str) do
    "[LEGACY] #{str}"
  end

  defp string_formatter(other), do: other

  defp context_formatter(%Ctx{} = ctx) do
    Ctx.update_meta(ctx, %{formatted: true})
  end

  defp context_formatter(other), do: other

  defp universal_formatter(str) when is_binary(str) do
    "[UNIVERSAL] #{str}"
  end

  defp universal_formatter(%Ctx{} = ctx) do
    Ctx.update_meta(ctx, %{universal: true})
  end

  defp universal_formatter(other), do: other
end
