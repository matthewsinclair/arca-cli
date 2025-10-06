defmodule Arca.Cli.Output.PlainRendererTest do
  use ExUnit.Case
  alias Arca.Cli.Ctx
  alias Arca.Cli.Output.PlainRenderer

  describe "render/1 - main rendering" do
    test "renders empty context" do
      ctx = Ctx.new(%{}, %{})
      result = PlainRenderer.render(ctx)
      assert result == []
    end

    test "renders context with multiple output items" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:info, "Starting process"})
        |> Ctx.add_output({:success, "Process completed"})

      result =
        ctx
        |> PlainRenderer.render()
        |> IO.iodata_to_binary()

      assert result == "Starting process\n✓ Process completed"
    end

    test "renders errors from context errors field" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_error("Something went wrong")
        |> Ctx.add_error("Another error occurred")

      result =
        ctx
        |> PlainRenderer.render()
        |> IO.iodata_to_binary()

      assert result == "✗ Something went wrong\n✗ Another error occurred"
    end

    test "renders both errors and output" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:info, "Processing"})
        |> Ctx.add_error("Failed to complete")
        |> Ctx.complete(:error)

      result =
        ctx
        |> PlainRenderer.render()
        |> IO.iodata_to_binary()

      assert result == "✗ Failed to complete\n\nProcessing"
    end
  end

  describe "render_item/1 - message types" do
    test "renders success message" do
      result =
        {:success, "Operation successful"}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "✓ Operation successful"
    end

    test "renders error message" do
      result =
        {:error, "Operation failed"}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "✗ Operation failed"
    end

    test "renders warning message" do
      result =
        {:warning, "This is a warning"}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "⚠ This is a warning"
    end

    test "renders info message" do
      result =
        {:info, "Information message"}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "Information message"
    end

    test "renders text content" do
      result =
        {:text, "Plain text content"}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "Plain text content"
    end
  end

  describe "render_item/1 - tables" do
    test "renders table with headers" do
      rows = [
        ["Alice", "30"],
        ["Bob", "25"]
      ]

      result =
        {:table, rows, headers: ["Name", "Age"]}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Verify it contains box-drawing table elements
      # Top-left corner
      assert result =~ "┌"
      # Vertical line
      assert result =~ "│"
      # Horizontal line
      assert result =~ "─"
      assert result =~ "Name"
      assert result =~ "Age"
      assert result =~ "Alice"
      assert result =~ "30"
      assert result =~ "Bob"
      assert result =~ "25"

      # Verify no ANSI codes
      refute result =~ "\x1b["
    end

    test "renders table without headers" do
      rows = [
        ["Alice", "30"],
        ["Bob", "25"]
      ]

      result =
        {:table, rows, []}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Should generate generic column headers
      assert result =~ "Column 1"
      assert result =~ "Column 2"
      assert result =~ "Alice"
      assert result =~ "Bob"
    end

    test "renders table with map rows" do
      rows = [
        %{"Name" => "Alice", "Age" => 30},
        %{"Name" => "Bob", "Age" => 25}
      ]

      result =
        {:table, rows, []}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result =~ "Name"
      assert result =~ "Age"
      assert result =~ "Alice"
      assert result =~ "30"
      assert result =~ "Bob"
      assert result =~ "25"
    end

    test "renders empty table" do
      result =
        {:table, [], headers: ["Name", "Age"]}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "(empty table)"
    end

    test "renders table with headers automatically used as column order" do
      rows = [
        %{"subdomain" => "api", "name" => "Service A", "status" => "active", "theme" => "light"},
        %{"subdomain" => "web", "name" => "Service B", "status" => "inactive", "theme" => "dark"}
      ]

      result =
        {:table, rows, headers: ["subdomain", "name", "status", "theme"]}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Extract the header line (first line with column names)
      lines = String.split(result, "\n")
      header_line = Enum.find(lines, fn line -> line =~ "subdomain" end)

      # Verify columns appear in the specified order from headers
      # subdomain should appear before name, name before status, etc.
      subdomain_pos = :binary.match(header_line, "subdomain") |> elem(0)
      name_pos = :binary.match(header_line, "name") |> elem(0)
      status_pos = :binary.match(header_line, "status") |> elem(0)
      theme_pos = :binary.match(header_line, "theme") |> elem(0)

      assert subdomain_pos < name_pos
      assert name_pos < status_pos
      assert status_pos < theme_pos
    end

    test "renders table with explicit column_order overriding headers" do
      rows = [
        %{"subdomain" => "api", "name" => "Service A", "status" => "active"}
      ]

      result =
        {:table, rows,
         headers: ["subdomain", "name", "status"], column_order: ["status", "name", "subdomain"]}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Extract the header line
      lines = String.split(result, "\n")
      header_line = Enum.find(lines, fn line -> line =~ "subdomain" end)

      # Verify columns appear in the column_order, not headers order
      status_pos = :binary.match(header_line, "status") |> elem(0)
      name_pos = :binary.match(header_line, "name") |> elem(0)
      subdomain_pos = :binary.match(header_line, "subdomain") |> elem(0)

      assert status_pos < name_pos
      assert name_pos < subdomain_pos
    end

    test "renders table without column_order defaults to alphabetical" do
      rows = [
        %{"zebra" => "Z", "apple" => "A", "banana" => "B"}
      ]

      result =
        {:table, rows, []}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Extract the header line
      lines = String.split(result, "\n")
      header_line = Enum.find(lines, fn line -> line =~ "apple" end)

      # Verify columns appear in alphabetical order
      apple_pos = :binary.match(header_line, "apple") |> elem(0)
      banana_pos = :binary.match(header_line, "banana") |> elem(0)
      zebra_pos = :binary.match(header_line, "zebra") |> elem(0)

      assert apple_pos < banana_pos
      assert banana_pos < zebra_pos
    end

    test "renders table with column_order :desc" do
      rows = [
        %{"alpha" => "A", "beta" => "B", "gamma" => "G"}
      ]

      result =
        {:table, rows, column_order: :desc}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Extract the header line
      lines = String.split(result, "\n")
      header_line = Enum.find(lines, fn line -> line =~ "alpha" end)

      # Verify columns appear in descending alphabetical order
      alpha_pos = :binary.match(header_line, "alpha") |> elem(0)
      beta_pos = :binary.match(header_line, "beta") |> elem(0)
      gamma_pos = :binary.match(header_line, "gamma") |> elem(0)

      assert gamma_pos < beta_pos
      assert beta_pos < alpha_pos
    end

    test "renders table with has_headers using first row order" do
      rows = [
        ["Index", "Command", "Arguments"],
        ["0", "first", ""],
        ["1", "second", ""]
      ]

      result =
        {:table, rows, has_headers: true}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Extract the header line
      lines = String.split(result, "\n")
      header_line = Enum.find(lines, fn line -> line =~ "Index" end)

      # Verify columns appear in the order from first row (Index, Command, Arguments)
      # NOT alphabetically (Arguments, Command, Index)
      index_pos = :binary.match(header_line, "Index") |> elem(0)
      command_pos = :binary.match(header_line, "Command") |> elem(0)
      arguments_pos = :binary.match(header_line, "Arguments") |> elem(0)

      assert index_pos < command_pos
      assert command_pos < arguments_pos
    end
  end

  describe "render_item/1 - lists" do
    test "renders list with title" do
      items = ["First item", "Second item", "Third item"]

      result =
        {:list, items, title: "My Items"}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "My Items:\n* First item\n* Second item\n* Third item"
    end

    test "renders list without title" do
      items = ["Apple", "Banana", "Cherry"]

      result =
        {:list, items, []}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "* Apple\n* Banana\n* Cherry"
    end

    test "renders empty list" do
      result =
        {:list, [], title: "Empty"}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "(empty list)"
    end

    test "renders list with non-string items" do
      items = [1, :atom, "string", %{key: "value"}]

      result =
        {:list, items, []}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result =~ "* 1"
      assert result =~ "* atom"
      assert result =~ "* string"
      assert result =~ "* %{key: \"value\"}"
    end
  end

  describe "render_item/1 - interactive elements" do
    test "renders spinner as static text" do
      result =
        {:spinner, "Loading data", fn -> :ok end}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "⟳ Loading data"
    end

    test "renders progress as static text" do
      result =
        {:progress, "Processing files", fn -> :ok end}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result == "◈ Processing files"
    end
  end

  describe "render_item/1 - edge cases" do
    test "returns nil for unknown item types" do
      assert PlainRenderer.render_item({:unknown, "data"}) == nil
      assert PlainRenderer.render_item("not a tuple") == nil
      assert PlainRenderer.render_item(42) == nil
    end

    test "handles nil values gracefully" do
      assert PlainRenderer.render_item(nil) == nil
    end
  end

  describe "complete context workflows" do
    test "renders a successful command execution" do
      ctx =
        Ctx.new(%{file: "data.csv"}, %{})
        |> Ctx.add_output({:info, "Processing file: data.csv"})
        |> Ctx.add_output({:info, "Reading 1000 rows"})
        |> Ctx.add_output(
          {:table, [["Count", "1000"], ["Status", "OK"]], headers: ["Metric", "Value"]}
        )
        |> Ctx.add_output({:success, "Processing complete"})
        |> Ctx.complete(:ok)

      result =
        ctx
        |> PlainRenderer.render()
        |> IO.iodata_to_binary()

      assert result =~ "Processing file: data.csv"
      assert result =~ "Reading 1000 rows"
      assert result =~ "Metric"
      assert result =~ "Value"
      assert result =~ "Count"
      assert result =~ "1000"
      assert result =~ "✓ Processing complete"
    end

    test "renders a failed command execution" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:info, "Starting operation"})
        |> Ctx.add_error("File not found: config.yml")
        |> Ctx.add_output({:error, "Operation aborted"})
        |> Ctx.complete(:error)

      result =
        ctx
        |> PlainRenderer.render()
        |> IO.iodata_to_binary()

      assert result =~ "✗ File not found: config.yml"
      assert result =~ "Starting operation"
      assert result =~ "✗ Operation aborted"
    end

    test "renders mixed output types" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:warning, "Deprecated function used"})
        |> Ctx.add_output({:list, ["Task 1", "Task 2"], title: "Tasks"})
        |> Ctx.add_output({:info, "Continuing with execution"})
        |> Ctx.complete(:warning)

      result =
        ctx
        |> PlainRenderer.render()
        |> IO.iodata_to_binary()

      assert result =~ "⚠ Deprecated function used"
      assert result =~ "Tasks:"
      assert result =~ "* Task 1"
      assert result =~ "* Task 2"
      assert result =~ "Continuing with execution"
    end
  end

  describe "ANSI code verification" do
    test "output contains no ANSI escape codes" do
      # Create a context with various output types
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:success, "Success with color"})
        |> Ctx.add_output({:error, "Error with color"})
        |> Ctx.add_output({:warning, "Warning with color"})
        |> Ctx.add_output({:table, [["Data", "Value"]], headers: ["Col1", "Col2"]})
        |> Ctx.add_output({:list, ["Item 1", "Item 2"], title: "List"})

      result =
        ctx
        |> PlainRenderer.render()
        |> IO.iodata_to_binary()

      # Check for common ANSI escape sequences
      # ESC[
      refute result =~ ~r/\x1b\[/
      # Color codes
      refute result =~ ~r/\x1b\[[0-9;]*m/
      # Clear line
      refute result =~ ~r/\x1b\[K/
      # Home cursor
      refute result =~ ~r/\x1b\[H/
    end

    test "strips any ANSI codes from Owl output" do
      # Even if Owl somehow outputs ANSI codes, they should be stripped
      rows = [["Test", "Data"]]

      result =
        {:table, rows, headers: ["Header1", "Header2"]}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # Verify no ANSI codes remain
      refute result =~ ~r/\x1b\[/
    end
  end

  describe "helper functions" do
    test "rows_to_maps converts list of lists with headers" do
      rows = [["Alice", 30], ["Bob", 25]]
      headers = ["Name", "Age"]

      # This is a private function, so we test it indirectly through table rendering
      result =
        {:table, rows, headers: headers}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      assert result =~ "Name"
      assert result =~ "Age"
      assert result =~ "Alice"
    end

    test "handles various data types in tables" do
      rows = [
        [nil, "value"],
        ["string", 123],
        [:atom, true]
      ]

      result =
        {:table, rows, headers: ["Type", "Example"]}
        |> PlainRenderer.render_item()
        |> IO.iodata_to_binary()

      # All values should be converted to strings
      assert result =~ "Type"
      assert result =~ "Example"
      assert result =~ "string"
      assert result =~ "123"
      assert result =~ "atom"
      assert result =~ "true"
    end
  end
end
