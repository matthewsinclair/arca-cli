defmodule Arca.Cli.Output.FancyRenderer do
  @moduledoc """
  Fancy renderer for Arca.Cli output with colors, symbols, and enhanced formatting.

  This renderer produces visually rich terminal output with:
  - Colored text for different message types
  - Enhanced symbols (✓, ✗, ⚠, ℹ)
  - Styled tables using Owl with borders and colors
  - Formatted lists with colored bullet points
  - Interactive elements like spinners and progress bars

  Falls back to PlainRenderer when TTY is not available.
  """

  alias Arca.Cli.Output.PlainRenderer

  @doc """
  Renders a context or output items with fancy formatting.

  ## Parameters

    - ctx_or_items: Either a %Arca.Cli.Ctx{} struct or a list of output items

  ## Returns

    - Formatted string with ANSI escape codes for colors and styling

  ## Examples

      iex> ctx = %Arca.Cli.Ctx{output: [{:success, "Done!"}]}
      iex> render(ctx)
      "✓ Done!"

      iex> render([{:error, "Failed"}])
      "✗ Failed"
  """
  @spec render(Arca.Cli.Ctx.t() | [Arca.Cli.Ctx.output_item()]) :: String.t()
  def render(%Arca.Cli.Ctx{meta: %{style: :plain}} = ctx) do
    ctx
    |> PlainRenderer.render()
    |> IO.iodata_to_binary()
  end

  def render(%Arca.Cli.Ctx{} = ctx) do
    ctx
    |> check_tty()
    |> do_render()
  end

  def render(items) when is_list(items) do
    %Arca.Cli.Ctx{output: items}
    |> check_tty()
    |> do_render()
  end

  # Private functions

  defp check_tty(%Arca.Cli.Ctx{} = ctx) do
    case System.get_env("TERM") do
      nil -> {:plain, ctx}
      "dumb" -> {:plain, ctx}
      _ -> {:fancy, ctx}
    end
  end

  defp do_render({:plain, ctx}) do
    ctx
    |> PlainRenderer.render()
    |> IO.iodata_to_binary()
  end

  defp do_render({:fancy, ctx}) do
    ctx.output
    |> Enum.map(&render_item/1)
    |> Enum.join("\n")
  end

  # Message renderers with colors and symbols

  defp render_item({:success, message}) do
    IO.ANSI.green() <> "✓ " <> message <> IO.ANSI.reset()
  end

  defp render_item({:error, message}) do
    IO.ANSI.red() <> "✗ " <> message <> IO.ANSI.reset()
  end

  defp render_item({:warning, message}) do
    IO.ANSI.yellow() <> "⚠ " <> message <> IO.ANSI.reset()
  end

  defp render_item({:info, message}) do
    IO.ANSI.cyan() <> "ℹ " <> message <> IO.ANSI.reset()
  end

  defp render_item({:text, message}) do
    message
  end

  # Table renderer with enhanced styling

  defp render_item({:table, rows, opts}) do
    table_opts =
      Keyword.merge(
        [
          border_style: :solid_rounded,
          divide_body_rows: false,
          padding_x: 1,
          render_cell: &colorize_cell/1
        ],
        opts
      )

    rows
    |> prepare_table_data()
    |> Owl.Table.new(table_opts)
    |> to_string()
  end

  # List renderer with colored bullets

  defp render_item({:list, items}) when is_list(items) do
    render_item({:list, items, []})
  end

  defp render_item({:list, items, opts}) when is_list(items) do
    title = Keyword.get(opts, :title)
    bullet_color = Keyword.get(opts, :bullet_color, :cyan)

    formatted_items =
      items
      |> Enum.map(fn item ->
        bullet = apply(IO.ANSI, bullet_color, []) <> "• " <> IO.ANSI.reset()
        bullet <> safe_to_string(item)
      end)

    if title do
      IO.ANSI.bright() <>
        title <> ":" <> IO.ANSI.reset() <> "\n" <> Enum.join(formatted_items, "\n")
    else
      Enum.join(formatted_items, "\n")
    end
  end

  # Interactive elements

  defp render_item({:spinner, label, func}) when is_function(func) do
    func
    |> execute_with_label(label, "⠿")
    |> format_execution_result()
  end

  defp render_item({:progress, label, func}) when is_function(func) do
    func
    |> execute_with_label(label, "▶")
    |> format_execution_result()
  end

  # Fallback for unknown items
  defp render_item(item) do
    IO.ANSI.faint() <> safe_to_string(item) <> IO.ANSI.reset()
  end

  defp execute_with_label(func, label, symbol) do
    header = IO.ANSI.cyan() <> symbol <> " " <> label <> "..." <> IO.ANSI.reset()
    result = func.()
    {header, result}
  end

  defp format_execution_result({header, {:ok, result}}) do
    header <> "\n" <> IO.ANSI.green() <> "  ✓ " <> safe_to_string(result) <> IO.ANSI.reset()
  end

  defp format_execution_result({header, {:error, reason}}) do
    header <> "\n" <> IO.ANSI.red() <> "  ✗ " <> safe_to_string(reason) <> IO.ANSI.reset()
  end

  defp format_execution_result({header, result}) do
    header <> "\n  " <> safe_to_string(result)
  end

  # Helper functions

  defp prepare_table_data(rows) when is_list(rows) do
    rows
    |> classify_rows()
    |> process_rows()
  end

  defp classify_rows(rows) do
    {rows, determine_row_type(rows)}
  end

  defp determine_row_type(rows) do
    case rows do
      [h | _] when is_map(h) -> :maps
      [h | _] when is_list(h) -> :lists
      _ -> :mixed
    end
  end

  defp process_rows({rows, :maps}) do
    Enum.map(rows, &stringify_map_values/1)
  end

  defp process_rows({rows, :lists}) do
    # For list of lists, convert to list of maps using first row as headers
    case rows do
      [headers | data] when data != [] ->
        headers_list = Enum.map(headers, &safe_to_string/1)

        Enum.map(data, fn row ->
          row
          |> Enum.map(&safe_to_string/1)
          |> Enum.zip(headers_list)
          |> Enum.map(fn {value, key} -> {key, value} end)
          |> Map.new()
        end)

      _ ->
        # If no headers or single row, just convert to strings
        Enum.map(rows, fn row ->
          row
          |> Enum.with_index()
          |> Enum.map(fn {value, idx} -> {"Col#{idx + 1}", safe_to_string(value)} end)
          |> Map.new()
        end)
    end
  end

  defp process_rows({rows, :mixed}) do
    Enum.map(rows, &process_mixed_row/1)
  end

  defp process_mixed_row(row) when is_list(row) do
    Enum.map(row, &safe_to_string/1)
  end

  defp process_mixed_row(row) when is_map(row) do
    stringify_map_values(row)
  end

  defp process_mixed_row(row) do
    [safe_to_string(row)]
  end

  defp stringify_map_values(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {k, safe_to_string(v)} end)
  end

  defp safe_to_string(nil), do: ""
  defp safe_to_string(value) when is_binary(value), do: value
  defp safe_to_string(value) when is_atom(value), do: to_string(value)
  defp safe_to_string(value) when is_number(value), do: to_string(value)
  defp safe_to_string(value), do: inspect(value)

  # Cell colorization for tables
  defp colorize_cell(cell) when is_binary(cell) do
    cell
    |> classify_cell()
    |> apply_cell_color(cell)
  end

  defp colorize_cell(cell), do: safe_to_string(cell)

  defp classify_cell(cell) do
    normalized = String.downcase(cell)

    cond do
      # Headers pattern - all uppercase
      cell =~ ~r/^[A-Z][A-Z\s]+$/ and cell == String.upcase(cell) -> :header
      # Numbers
      cell =~ ~r/^\d+(\.\d+)?$/ -> :number
      # Success keywords
      normalized in ["success", "ok", "true", "yes", "active"] -> :success
      # Error keywords
      normalized in ["error", "failed", "false", "no", "inactive"] -> :error
      # Warning keywords
      normalized in ["warning", "pending", "maybe"] -> :warning
      # Default
      true -> :default
    end
  end

  defp apply_cell_color(:header, cell), do: IO.ANSI.bright() <> cell <> IO.ANSI.reset()
  defp apply_cell_color(:number, cell), do: IO.ANSI.cyan() <> cell <> IO.ANSI.reset()
  defp apply_cell_color(:success, cell), do: IO.ANSI.green() <> cell <> IO.ANSI.reset()
  defp apply_cell_color(:error, cell), do: IO.ANSI.red() <> cell <> IO.ANSI.reset()
  defp apply_cell_color(:warning, cell), do: IO.ANSI.yellow() <> cell <> IO.ANSI.reset()
  defp apply_cell_color(:default, cell), do: cell
end
