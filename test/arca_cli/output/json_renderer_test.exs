defmodule Arca.Cli.Output.JsonRendererTest do
  use ExUnit.Case
  alias Arca.Cli.Ctx
  alias Arca.Cli.Output.JsonRenderer

  describe "render/1 with basic output types" do
    test "renders success message" do
      ctx = %Ctx{output: [{:success, "Operation completed"}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert decoded["status"] == "ok"
      assert [%{"type" => "success", "message" => "Operation completed"}] = decoded["output"]
    end

    test "renders error message" do
      ctx = %Ctx{output: [{:error, "Operation failed"}], status: :error}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert decoded["status"] == "error"
      assert [%{"type" => "error", "message" => "Operation failed"}] = decoded["output"]
    end

    test "renders warning message" do
      ctx = %Ctx{output: [{:warning, "This is a warning"}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "warning", "message" => "This is a warning"}] = decoded["output"]
    end

    test "renders info message" do
      ctx = %Ctx{output: [{:info, "Information"}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "info", "message" => "Information"}] = decoded["output"]
    end

    test "renders text content" do
      ctx = %Ctx{output: [{:text, "Plain text"}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "text", "content" => "Plain text"}] = decoded["output"]
    end
  end

  describe "render/1 with JSON output type" do
    test "embeds JSON data directly without double-encoding" do
      data = %{foo: "bar", count: 42}
      ctx = %Ctx{output: [{:json, data}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert decoded["status"] == "ok"
      assert [%{"type" => "json", "data" => embedded_data}] = decoded["output"]
      assert embedded_data["foo"] == "bar"
      assert embedded_data["count"] == 42
    end

    test "embeds JSON data with options (ignores opts in output)" do
      data = %{foo: "bar"}
      ctx = %Ctx{output: [{:json, data, [pretty: false]}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "json", "data" => embedded_data}] = decoded["output"]
      assert embedded_data["foo"] == "bar"
      # Options should not appear in output, just the data
      refute Map.has_key?(embedded_data, "pretty")
    end

    test "handles nested JSON structures" do
      data = %{
        user: %{
          name: "Alice",
          settings: %{
            theme: "dark"
          }
        },
        tags: ["admin", "editor"]
      }

      ctx = %Ctx{output: [{:json, data}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "json", "data" => embedded_data}] = decoded["output"]
      assert embedded_data["user"]["name"] == "Alice"
      assert embedded_data["user"]["settings"]["theme"] == "dark"
      assert embedded_data["tags"] == ["admin", "editor"]
    end

    test "handles various data types in JSON" do
      data = %{
        string: "text",
        number: 123,
        float: 45.67,
        boolean: false,
        null: nil,
        array: [1, 2, 3]
      }

      ctx = %Ctx{output: [{:json, data}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "json", "data" => embedded_data}] = decoded["output"]
      assert embedded_data["string"] == "text"
      assert embedded_data["number"] == 123
      assert embedded_data["float"] == 45.67
      assert embedded_data["boolean"] == false
      assert embedded_data["null"] == nil
      assert embedded_data["array"] == [1, 2, 3]
    end

    test "handles empty map" do
      data = %{}
      ctx = %Ctx{output: [{:json, data}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "json", "data" => embedded_data}] = decoded["output"]
      assert embedded_data == %{}
    end

    test "handles array as root element" do
      data = [1, 2, 3]
      ctx = %Ctx{output: [{:json, data}], status: :ok}
      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert [%{"type" => "json", "data" => embedded_data}] = decoded["output"]
      assert embedded_data == [1, 2, 3]
    end
  end

  describe "render/1 with mixed output types" do
    test "renders multiple output items including JSON" do
      ctx = %Ctx{
        output: [
          {:info, "Starting process"},
          {:json, %{status: "running", progress: 50}},
          {:success, "Process completed"}
        ],
        status: :ok
      }

      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert decoded["status"] == "ok"
      assert length(decoded["output"]) == 3

      assert %{"type" => "info", "message" => "Starting process"} = Enum.at(decoded["output"], 0)

      assert %{"type" => "json", "data" => json_data} = Enum.at(decoded["output"], 1)
      assert json_data["status"] == "running"
      assert json_data["progress"] == 50

      assert %{"type" => "success", "message" => "Process completed"} =
               Enum.at(decoded["output"], 2)
    end

    test "renders JSON alongside tables and lists" do
      ctx = %Ctx{
        output: [
          {:table, [%{name: "Alice", age: 30}], []},
          {:json, %{summary: "data processed"}},
          {:list, ["item1", "item2"], []}
        ],
        status: :ok
      }

      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      # Should have all three output items
      assert length(decoded["output"]) == 3

      # Verify JSON is in the middle
      assert %{"type" => "json", "data" => json_data} = Enum.at(decoded["output"], 1)
      assert json_data["summary"] == "data processed"
    end
  end

  describe "render/1 with context metadata" do
    test "includes command in output" do
      ctx = %Ctx{
        command: "test.command",
        output: [{:json, %{result: "success"}}],
        status: :ok
      }

      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      assert decoded["command"] == "test.command"
    end

    test "excludes empty metadata fields" do
      ctx = %Ctx{
        output: [{:json, %{foo: "bar"}}],
        status: :ok,
        errors: [],
        cargo: %{},
        meta: %{}
      }

      result = JsonRenderer.render(ctx)
      decoded = Jason.decode!(result)

      # Should not include empty errors, cargo, or meta
      refute Map.has_key?(decoded, "errors")
      refute Map.has_key?(decoded, "cargo")
      refute Map.has_key?(decoded, "meta")
    end
  end

  describe "render/1 output format" do
    test "produces valid JSON" do
      ctx = %Ctx{
        output: [{:json, %{test: "data"}}],
        status: :ok
      }

      result = JsonRenderer.render(ctx)

      # Should not raise
      assert {:ok, _decoded} = Jason.decode(result)
    end

    test "produces pretty-printed JSON by default" do
      ctx = %Ctx{
        output: [{:json, %{foo: "bar"}}],
        status: :ok
      }

      result = JsonRenderer.render(ctx)

      # Pretty-printed JSON should have newlines
      assert result =~ "\n"
    end
  end
end
