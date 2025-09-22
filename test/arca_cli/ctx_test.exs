defmodule Arca.Cli.CtxTest do
  use ExUnit.Case
  alias Arca.Cli.Ctx

  describe "new/2 and new/3" do
    test "creates a new context with default values" do
      ctx = Ctx.new(%{}, %{})

      assert ctx.command == nil
      assert ctx.args == %{}
      assert ctx.options == %{}
      assert ctx.output == []
      assert ctx.errors == []
      assert ctx.status == nil
      assert ctx.cargo == %{}
      assert ctx.meta == %{}
    end

    test "creates context with provided args" do
      args = %{name: "test", value: 42}
      ctx = Ctx.new(args, %{})

      assert ctx.args == args
    end

    test "creates context with command and options" do
      ctx = Ctx.new(%{}, %{}, command: :about, options: %{verbose: true})

      assert ctx.command == :about
      assert ctx.options == %{verbose: true}
    end

    test "handles nil args gracefully" do
      ctx = Ctx.new(nil, %{})
      assert ctx.args == %{}
    end

    test "extracts style from settings" do
      settings = %{"style" => "plain"}
      ctx = Ctx.new(%{}, settings)

      assert ctx.meta == %{style: :plain}
    end

    test "extracts no_color from settings" do
      settings = %{"no_color" => true}
      ctx = Ctx.new(%{}, settings)

      assert ctx.meta == %{no_color: true}
    end

    test "extracts multiple meta values from settings" do
      settings = %{"style" => "fancy", "no_color" => true}
      ctx = Ctx.new(%{}, settings)

      assert ctx.meta == %{style: :fancy, no_color: true}
    end
  end

  describe "add_output/2" do
    setup do
      {:ok, ctx: Ctx.new(%{}, %{})}
    end

    test "adds success message", %{ctx: ctx} do
      result = Ctx.add_output(ctx, {:success, "Operation completed"})

      assert result.output == [{:success, "Operation completed"}]
    end

    test "adds multiple output items in order", %{ctx: ctx} do
      result =
        ctx
        |> Ctx.add_output({:info, "Starting"})
        |> Ctx.add_output({:success, "Done"})

      assert result.output == [{:info, "Starting"}, {:success, "Done"}]
    end

    test "adds table output", %{ctx: ctx} do
      rows = [["Alice", 30], ["Bob", 25]]
      result = Ctx.add_output(ctx, {:table, rows, headers: ["Name", "Age"]})

      assert [{:table, ^rows, headers: ["Name", "Age"]}] = result.output
    end

    test "adds list output", %{ctx: ctx} do
      items = ["item1", "item2", "item3"]
      result = Ctx.add_output(ctx, {:list, items, title: "My List"})

      assert [{:list, ^items, title: "My List"}] = result.output
    end

    test "adds various message types", %{ctx: ctx} do
      result =
        ctx
        |> Ctx.add_output({:error, "Error occurred"})
        |> Ctx.add_output({:warning, "Warning message"})
        |> Ctx.add_output({:info, "Info message"})
        |> Ctx.add_output({:text, "Plain text"})

      assert length(result.output) == 4
      assert {:error, "Error occurred"} in result.output
      assert {:warning, "Warning message"} in result.output
      assert {:info, "Info message"} in result.output
      assert {:text, "Plain text"} in result.output
    end
  end

  describe "add_outputs/2" do
    test "adds multiple output items at once" do
      ctx = Ctx.new(%{}, %{})

      items = [
        {:info, "Step 1"},
        {:info, "Step 2"},
        {:success, "Complete"}
      ]

      result = Ctx.add_outputs(ctx, items)
      assert result.output == items
    end

    test "maintains order when adding outputs" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:info, "First"})

      items = [{:info, "Second"}, {:info, "Third"}]
      result = Ctx.add_outputs(ctx, items)

      assert result.output == [{:info, "First"}, {:info, "Second"}, {:info, "Third"}]
    end
  end

  describe "add_error/2" do
    setup do
      {:ok, ctx: Ctx.new(%{}, %{})}
    end

    test "adds error message", %{ctx: ctx} do
      result = Ctx.add_error(ctx, "Something went wrong")

      assert result.errors == ["Something went wrong"]
    end

    test "adds multiple errors in order", %{ctx: ctx} do
      result =
        ctx
        |> Ctx.add_error("Error 1")
        |> Ctx.add_error("Error 2")

      assert result.errors == ["Error 1", "Error 2"]
    end

    test "keeps errors separate from output", %{ctx: ctx} do
      result =
        ctx
        |> Ctx.add_output({:info, "Normal output"})
        |> Ctx.add_error("Error message")

      assert result.output == [{:info, "Normal output"}]
      assert result.errors == ["Error message"]
    end
  end

  describe "add_errors/2" do
    test "adds multiple error messages at once" do
      ctx = Ctx.new(%{}, %{})
      errors = ["Error 1", "Error 2", "Error 3"]

      result = Ctx.add_errors(ctx, errors)
      assert result.errors == errors
    end

    test "appends to existing errors" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_error("First error")

      result = Ctx.add_errors(ctx, ["Second", "Third"])
      assert result.errors == ["First error", "Second", "Third"]
    end
  end

  describe "with_cargo/2" do
    test "sets cargo data" do
      ctx = Ctx.new(%{}, %{})
      result = Ctx.with_cargo(ctx, %{processed: 42, skipped: 3})

      assert result.cargo == %{processed: 42, skipped: 3}
    end

    test "replaces existing cargo" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.with_cargo(%{old: "data"})

      result = Ctx.with_cargo(ctx, %{new: "data"})

      assert result.cargo == %{new: "data"}
    end
  end

  describe "update_cargo/2" do
    test "merges with existing cargo" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.with_cargo(%{existing: "value", count: 1})

      result = Ctx.update_cargo(ctx, %{count: 2, new_field: "new"})

      assert result.cargo == %{existing: "value", count: 2, new_field: "new"}
    end

    test "works with empty cargo" do
      ctx = Ctx.new(%{}, %{})
      result = Ctx.update_cargo(ctx, %{field: "value"})

      assert result.cargo == %{field: "value"}
    end
  end

  describe "complete/2" do
    test "sets status to :ok" do
      ctx = Ctx.new(%{}, %{})
      result = Ctx.complete(ctx, :ok)

      assert result.status == :ok
    end

    test "sets status to :error" do
      ctx = Ctx.new(%{}, %{})
      result = Ctx.complete(ctx, :error)

      assert result.status == :error
    end

    test "sets status to :warning" do
      ctx = Ctx.new(%{}, %{})
      result = Ctx.complete(ctx, :warning)

      assert result.status == :warning
    end

    test "can change status" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.complete(:ok)

      result = Ctx.complete(ctx, :error)

      assert result.status == :error
    end
  end

  describe "set_meta/3" do
    test "sets metadata value" do
      ctx = Ctx.new(%{}, %{})
      result = Ctx.set_meta(ctx, :style, :plain)

      assert result.meta == %{style: :plain}
    end

    test "adds to existing metadata" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.set_meta(:style, :fancy)

      result = Ctx.set_meta(ctx, :no_color, true)

      assert result.meta == %{style: :fancy, no_color: true}
    end

    test "overwrites existing key" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.set_meta(:style, :fancy)

      result = Ctx.set_meta(ctx, :style, :plain)

      assert result.meta == %{style: :plain}
    end
  end

  describe "update_meta/2" do
    test "merges metadata maps" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.set_meta(:existing, "value")

      result = Ctx.update_meta(ctx, %{style: :plain, format: :json})

      assert result.meta == %{existing: "value", style: :plain, format: :json}
    end

    test "overwrites existing keys during merge" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.update_meta(%{style: :fancy, format: :text})

      result = Ctx.update_meta(ctx, %{style: :plain})

      assert result.meta == %{style: :plain, format: :text}
    end
  end

  describe "to_string/1" do
    test "formats empty context" do
      ctx = Ctx.new(%{}, %{})
      result = Ctx.to_string(ctx)

      assert result =~ "Status: pending"
      assert result =~ "Output: 0 items"
      assert result =~ "Errors: 0"
    end

    test "formats context with status" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.complete(:ok)

      result = Ctx.to_string(ctx)

      assert result =~ "Status: ok"
    end

    test "formats context with output items" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:success, "Great!"})
        |> Ctx.add_output({:info, "Information"})

      result = Ctx.to_string(ctx)

      assert result =~ "Output: 2 items"
      assert result =~ "[success] Great!"
      assert result =~ "[info] Information"
    end

    test "formats context with errors" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_error("Error 1")
        |> Ctx.add_error("Error 2")

      result = Ctx.to_string(ctx)

      assert result =~ "Errors: 2"
      assert result =~ "- Error 1"
      assert result =~ "- Error 2"
    end

    test "formats context with cargo" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.with_cargo(%{count: 42})

      result = Ctx.to_string(ctx)

      assert result =~ "Cargo: %{count: 42}"
    end

    test "formats table output items" do
      rows = [["A", "B"], ["C", "D"]]
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:table, rows, headers: ["Col1", "Col2"]})

      result = Ctx.to_string(ctx)

      assert result =~ "[table] 2 rows"
      assert result =~ "headers: [\"Col1\", \"Col2\"]"
    end

    test "formats list output items" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:list, ["a", "b", "c"], title: "Items"})

      result = Ctx.to_string(ctx)

      assert result =~ "[list] 3 items"
      assert result =~ "title: \"Items\""
    end

    test "truncates long text content" do
      long_text = String.duplicate("x", 100)
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:text, long_text})

      result = Ctx.to_string(ctx)

      assert result =~ "[text] #{String.slice(long_text, 0, 50)}..."
    end
  end

  describe "complex workflows" do
    test "full command execution workflow" do
      ctx =
        Ctx.new(%{file: "test.txt"}, %{"style" => "plain"}, command: :process)
        |> Ctx.add_output({:info, "Processing file: test.txt"})
        |> Ctx.add_output({:info, "Reading content..."})
        |> Ctx.with_cargo(%{lines_processed: 100})
        |> Ctx.add_output({:success, "Processing complete"})
        |> Ctx.complete(:ok)

      assert ctx.command == :process
      assert ctx.args == %{file: "test.txt"}
      assert ctx.meta == %{style: :plain}
      assert length(ctx.output) == 3
      assert ctx.cargo == %{lines_processed: 100}
      assert ctx.status == :ok
    end

    test "error handling workflow" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_output({:info, "Starting operation"})
        |> Ctx.add_error("File not found")
        |> Ctx.add_error("Permission denied")
        |> Ctx.add_output({:error, "Operation failed"})
        |> Ctx.complete(:error)

      assert length(ctx.output) == 2
      assert length(ctx.errors) == 2
      assert ctx.status == :error
    end

    test "progressive data building" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.set_meta(:format, :json)
        |> Ctx.update_cargo(%{step: 1})
        |> Ctx.add_output({:info, "Step 1"})
        |> Ctx.update_cargo(%{step: 2, data: []})
        |> Ctx.add_output({:info, "Step 2"})
        |> Ctx.update_cargo(%{step: 3, data: [1, 2, 3]})
        |> Ctx.complete(:ok)

      assert ctx.meta == %{format: :json}
      assert ctx.cargo == %{step: 3, data: [1, 2, 3]}
      assert length(ctx.output) == 2
    end
  end

  describe "edge cases" do
    test "handles empty lists gracefully" do
      ctx =
        Ctx.new(%{}, %{})
        |> Ctx.add_outputs([])
        |> Ctx.add_errors([])

      assert ctx.output == []
      assert ctx.errors == []
    end

    test "handles nil settings gracefully" do
      ctx = Ctx.new(%{}, nil)
      assert ctx.meta == %{}
    end

    test "handles non-map settings gracefully" do
      ctx = Ctx.new(%{}, "invalid")
      assert ctx.meta == %{}
    end
  end
end