defmodule Arca.Cli.Output.JsonRenderer do
  @moduledoc """
  JSON renderer for Arca.Cli output.

  This renderer produces JSON output for structured data, suitable for:
  - Machine-readable output
  - API integration
  - Automation and scripting

  The JSON output is pretty-printed for readability.
  """

  alias Arca.Cli.Ctx

  @doc """
  Renders a context as pretty-printed JSON.

  ## Parameters
    - ctx: The Context struct to render

  ## Returns
    - JSON string representation of the context

  ## Examples

      iex> ctx = %Ctx{output: [{:success, "Done"}], status: :ok}
      iex> JsonRenderer.render(ctx)
      ~s({"status": "ok", "output": [{"type": "success", "message": "Done"}]})
  """
  @spec render(Ctx.t()) :: String.t()
  def render(%Ctx{} = ctx) do
    ctx
    |> to_json_map()
    |> Jason.encode!(pretty: true)
  end

  # Convert Context to JSON-serializable map
  defp to_json_map(%Ctx{} = ctx) do
    %{
      command: ctx.command,
      status: ctx.status,
      output: format_output(ctx.output),
      errors: ctx.errors,
      cargo: ctx.cargo,
      meta: ctx.meta
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] || v == %{} end)
    |> Map.new()
  end

  # Format output items for JSON
  defp format_output(output) when is_list(output) do
    Enum.map(output, &format_output_item/1)
  end

  defp format_output(_), do: []

  # Convert output items to JSON-friendly format
  defp format_output_item({:success, message}) do
    %{type: "success", message: message}
  end

  defp format_output_item({:error, message}) do
    %{type: "error", message: message}
  end

  defp format_output_item({:warning, message}) do
    %{type: "warning", message: message}
  end

  defp format_output_item({:info, message}) do
    %{type: "info", message: message}
  end

  defp format_output_item({:text, content}) do
    %{type: "text", content: content}
  end

  defp format_output_item({:table, rows, opts}) do
    %{
      type: "table",
      rows: rows,
      options: Enum.into(opts, %{})
    }
  end

  defp format_output_item({:list, items, opts}) do
    %{
      type: "list",
      items: items,
      options: Enum.into(opts, %{})
    }
  end

  defp format_output_item({:spinner, label, _func}) do
    %{type: "spinner", label: label}
  end

  defp format_output_item({:progress, label, _func}) do
    %{type: "progress", label: label}
  end

  defp format_output_item(other) do
    %{type: "unknown", data: inspect(other)}
  end
end
