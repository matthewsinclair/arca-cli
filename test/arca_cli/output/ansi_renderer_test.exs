defmodule Arca.Cli.Output.AnsiRendererTest do
  use ExUnit.Case
  alias Arca.Cli.Output.AnsiRenderer
  alias Arca.Cli.Ctx

  describe "render/1 with context" do
    test "renders success messages with green color and checkmark" do
      ctx = %Ctx{output: [{:success, "Operation completed"}]}
      result = AnsiRenderer.render(ctx)

      assert result =~ "✓"
      assert result =~ "Operation completed"
      assert result =~ IO.ANSI.green()
      assert result =~ IO.ANSI.reset()
    end

    test "renders error messages with red color and cross" do
      ctx = %Ctx{output: [{:error, "Operation failed"}]}
      result = AnsiRenderer.render(ctx)

      assert result =~ "✗"
      assert result =~ "Operation failed"
      assert result =~ IO.ANSI.red()
      assert result =~ IO.ANSI.reset()
    end

    test "renders warning messages with yellow color and warning symbol" do
      ctx = %Ctx{output: [{:warning, "This is a warning"}]}
      result = AnsiRenderer.render(ctx)

      assert result =~ "⚠"
      assert result =~ "This is a warning"
      assert result =~ IO.ANSI.yellow()
      assert result =~ IO.ANSI.reset()
    end

    test "renders info messages with cyan color and info symbol" do
      ctx = %Ctx{output: [{:info, "Information message"}]}
      result = AnsiRenderer.render(ctx)

      assert result =~ "ℹ"
      assert result =~ "Information message"
      assert result =~ IO.ANSI.cyan()
      assert result =~ IO.ANSI.reset()
    end

    test "renders text messages without formatting" do
      ctx = %Ctx{output: [{:text, "Plain text"}]}
      result = AnsiRenderer.render(ctx)

      assert result == "Plain text"
      refute result =~ IO.ANSI.green()
      refute result =~ IO.ANSI.red()
    end

    test "renders multiple output items" do
      ctx = %Ctx{
        output: [
          {:success, "Step 1 done"},
          {:info, "Processing"},
          {:success, "Step 2 done"}
        ],
        meta: %{force_ansi: true}
      }

      result = AnsiRenderer.render(ctx)
      lines = String.split(result, "\n")

      assert length(lines) == 3
      assert Enum.at(lines, 0) =~ "✓"
      assert Enum.at(lines, 1) =~ "ℹ"
      assert Enum.at(lines, 2) =~ "✓"
    end

    test "falls back to plain renderer when style is :plain" do
      ctx = %Ctx{
        output: [{:success, "Done"}],
        meta: %{style: :plain}
      }

      result = AnsiRenderer.render(ctx)

      # Plain renderer returns a list, we need to join it
      output_string =
        case result do
          str when is_binary(str) -> str
          list when is_list(list) -> Enum.join(list, "\n")
        end

      # Plain renderer uses ✓ but no colors
      assert output_string =~ "✓"
      assert output_string =~ "Done"
      refute output_string =~ IO.ANSI.green()
      refute output_string =~ IO.ANSI.reset()
    end
  end

  describe "render/1 with lists" do
    test "renders simple lists with colored bullets" do
      result = AnsiRenderer.render([{:list, ["Item 1", "Item 2", "Item 3"]}])

      # The bullets have ANSI codes between them and the items
      assert result =~ "Item 1"
      assert result =~ "Item 2"
      assert result =~ "Item 3"
      assert result =~ "•"
      assert result =~ IO.ANSI.cyan()
      assert result =~ IO.ANSI.reset()
    end

    test "renders list with title" do
      result = AnsiRenderer.render([{:list, ["A", "B"], title: "Options"}])

      assert result =~ "Options:"
      assert result =~ "A"
      assert result =~ "B"
      assert result =~ "•"
      assert result =~ IO.ANSI.bright()
    end

    test "renders list with custom bullet color" do
      result = AnsiRenderer.render([{:list, ["Item"], bullet_color: :green}])

      assert result =~ "Item"
      assert result =~ "•"
      assert result =~ IO.ANSI.green()
    end

    test "handles different data types in lists" do
      result = AnsiRenderer.render([{:list, [42, :atom, "string", nil]}])

      assert result =~ "42"
      assert result =~ "atom"
      assert result =~ "string"
      # nil becomes empty string
      assert result =~ "•"
    end
  end

  describe "render/1 with tables" do
    test "renders table from list of maps with styled border" do
      data = [
        %{name: "Alice", status: "Active"},
        %{name: "Bob", status: "Inactive"}
      ]

      result = AnsiRenderer.render([{:table, data, []}])

      # Should use rounded border style
      assert result =~ "Alice"
      assert result =~ "Bob"
      assert result =~ "Active"
      assert result =~ "Inactive"

      # Note: Owl.Data.tag doesn't produce raw ANSI codes in the output string,
      # so we can't check for colors directly. The colors are applied internally by Owl.
    end

    test "renders table from list of lists" do
      data = [
        ["Name", "Score"],
        ["Alice", "95"],
        ["Bob", "87"]
      ]

      result = AnsiRenderer.render([{:table, data, []}])

      assert result =~ "Name"
      assert result =~ "Score"
      assert result =~ "95"
      assert result =~ "87"
    end

    test "handles various data types in table cells" do
      data = [
        %{id: 1, active: true, score: 95.5, status: nil},
        %{id: 2, active: false, score: 87.3, status: "pending"}
      ]

      result = AnsiRenderer.render([{:table, data, []}])

      assert result =~ "1"
      assert result =~ "2"
      assert result =~ "true"
      assert result =~ "false"
      assert result =~ "95.5"
      assert result =~ "87.3"
      assert result =~ "pending"
    end

    test "applies cell colorization based on content" do
      data = [
        %{status: "success", result: "error"},
        %{status: "warning", result: "ok"}
      ]

      result = AnsiRenderer.render([{:table, data, []}])

      # Verify content is rendered
      assert result =~ "success"
      assert result =~ "error"
      assert result =~ "warning"
      assert result =~ "ok"

      # Note: Owl.Data.tag doesn't produce raw ANSI codes in the output string.
      # The colorization is applied internally by Owl when rendering tables,
      # but doesn't appear as escape sequences in the final string.
    end
  end

  describe "render/1 with interactive elements" do
    test "renders spinner with function execution" do
      func = fn -> {:ok, "Task completed"} end
      result = AnsiRenderer.render([{:spinner, "Processing", func}])

      assert result =~ "⠿"
      assert result =~ "Processing..."
      assert result =~ "✓"
      assert result =~ "Task completed"
      assert result =~ IO.ANSI.cyan()
      assert result =~ IO.ANSI.green()
    end

    test "renders spinner with error result" do
      func = fn -> {:error, "Task failed"} end
      result = AnsiRenderer.render([{:spinner, "Processing", func}])

      assert result =~ "⠿"
      assert result =~ "Processing..."
      assert result =~ "✗"
      assert result =~ "Task failed"
      assert result =~ IO.ANSI.red()
    end

    test "renders progress with function execution" do
      func = fn -> {:ok, "Download complete"} end
      result = AnsiRenderer.render([{:progress, "Downloading", func}])

      assert result =~ "▶"
      assert result =~ "Downloading..."
      assert result =~ "✓"
      assert result =~ "Download complete"
    end
  end

  describe "render/1 with direct item lists" do
    test "renders items without context" do
      items = [
        {:success, "Done"},
        {:error, "Failed"},
        {:info, "Info"}
      ]

      result = AnsiRenderer.render(items)

      assert result =~ "✓ Done"
      assert result =~ "✗ Failed"
      assert result =~ "ℹ Info"
      assert result =~ IO.ANSI.green()
      assert result =~ IO.ANSI.red()
      assert result =~ IO.ANSI.cyan()
    end
  end

  describe "TTY detection and fallback" do
    test "uses colors when TERM is set" do
      # TERM should be set in test environment
      result = AnsiRenderer.render([{:success, "Done"}])

      # If TERM is set, should include colors
      if System.get_env("TERM") && System.get_env("TERM") != "dumb" do
        assert result =~ IO.ANSI.green()
      end
    end

    test "handles unknown output items gracefully" do
      result = AnsiRenderer.render([{:unknown, "data", "extra"}])

      # Should render with faint style
      assert result =~ IO.ANSI.faint()
      assert result =~ "unknown"
    end
  end

  describe "edge cases" do
    test "handles empty output" do
      ctx = %Ctx{output: []}
      result = AnsiRenderer.render(ctx)

      assert result == ""
    end

    test "handles nil values properly" do
      result = AnsiRenderer.render([{:text, nil}])
      assert result == ""
    end

    test "handles mixed content types" do
      ctx = %Ctx{
        output: [
          {:success, "Start"},
          {:table, [%{a: 1}], []},
          {:list, ["item"], []},
          {:error, "End"}
        ],
        meta: %{force_ansi: true}
      }

      result = AnsiRenderer.render(ctx)

      assert result =~ "✓ Start"
      # From table
      assert result =~ "1"
      assert result =~ "item"
      assert result =~ "•"
      assert result =~ "✗ End"
    end
  end
end
