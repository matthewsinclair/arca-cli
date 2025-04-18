defmodule Arca.Cli.Utils.OwlHelper do
  @moduledoc """
  Helper functions for working with Owl tables.
  Provides functionality to adjust column widths based on preferences and terminal width.
  """

  @type column_spec :: atom() | String.t()
  @type width_spec :: pos_integer() | {float(), :percent}
  @type column_preferences :: %{column_spec() => width_spec()}

  @default_table_options [
    divide_body_rows: false,
    word_wrap: :normal,
    padding_x: 1,
    border_style: :solid_rounded,
    sort_columns: :asc
  ]

  @doc """
  Adjusts column widths based on preferences and maximum width.

  Returns a function that can be passed to Owl.Table's `:max_column_widths` option.

  ## Parameters

  * `column_preferences` - Map of column names to their preferred widths
  * `max_width` - Maximum total width for the table, defaults to terminal width

  ## Width specifications

  Column width can be specified as:
  * Positive integer - explicit character width
  * `{float, :percent}` - percentage of available width after fixed columns

  ## Examples

      # Fixed widths for ID and Name, percentages for Description and Source
      preferences = %{
        "ID" => 15,
        "Name" => 15,
        "Description" => {0.6, :percent},
        "Source" => {0.4, :percent}
      }

      # Use with Owl.Table
      Owl.Table.new(data, max_column_widths: OwlHelper.adjust_column_widths(preferences, 80))
  """
  @spec adjust_column_widths(column_preferences(), pos_integer() | nil) ::
          (column_spec() -> pos_integer() | :infinity)
  def adjust_column_widths(column_preferences, max_width \\ nil) do
    max_width = max_width || Owl.IO.columns() || 80

    # Account for borders and padding in width calculations
    # We assume default padding_x of 1, which means 2 chars per column for padding
    # For many columns, reduce padding allocation to avoid excessive constraints
    padding_per_column = if map_size(column_preferences) > 4, do: 2, else: 3
    available_width = max_width - 1 - map_size(column_preferences) * padding_per_column

    # Separate fixed width columns from percentage-based
    {fixed_columns, percent_columns} =
      Enum.split_with(column_preferences, fn {_col, width} ->
        is_integer(width)
      end)

    # Calculate total fixed width
    fixed_width_total = Enum.reduce(fixed_columns, 0, fn {_col, width}, acc -> acc + width end)

    # Calculate remaining width for percentage columns
    remaining_width = max(0, available_width - fixed_width_total)

    # Calculate actual widths for percent-based columns
    percent_widths =
      Enum.map(percent_columns, fn {col, {percent, :percent}} ->
        {col, max(1, floor(remaining_width * percent))}
      end)

    # Combine fixed and calculated widths
    all_widths = Map.new(fixed_columns ++ percent_widths)

    # Return a function that Owl.Table can use for max_column_widths
    fn col ->
      # Default column width if not specified
      # Use a smaller default width when many columns are present
      default_width = if map_size(column_preferences) > 4, do: 6, else: 10
      Map.get(all_widths, col, default_width)
    end
  end

  @doc """
  Creates a new Owl table with adjusted column widths.

  ## Parameters

  * `data` - Table data (list of maps)
  * `column_preferences` - Map of column names to their preferred widths
  * `opts` - Additional options to pass to Owl.Table.new/2

  ## Options

  In addition to all Owl.Table options, OwlHelper supports:

  * `:column_order` - Specifies the order of columns. Can be:
    * A list of column names in the desired order (e.g., ["Name", "ID", "Description"])
    * `:asc` or `:desc` for alphabetical ordering
    * A custom sorting function `(column, column -> boolean())`
  * `:max_width` - Maximum width for the table. Defaults to the terminal width if available, or 80 characters otherwise.

  ## Examples

      preferences = %{
        "ID" => 15,
        "Name" => 15,
        "Description" => {0.6, :percent},
        "Source" => {0.4, :percent}
      }

      # Basic usage (automatically uses terminal width)
      OwlHelper.table(data, preferences)

      # Specifying column order
      OwlHelper.table(data, preferences, column_order: ["Name", "ID", "Description", "Source"])

      # Overriding max width
      OwlHelper.table(data, preferences, max_width: 120)

      # Setting multiple options
      OwlHelper.table(data, preferences, max_width: 100, sort_columns: :desc, divide_body_rows: false)
  """
  @spec table(list(map()), column_preferences(), keyword()) :: Owl.Data.t()
  def table(data, column_preferences, opts \\ []) do
    # Get max_width from options or default to terminal width
    max_width = Keyword.get(opts, :max_width) || Owl.IO.columns() || 80

    # Merge our default options with any custom options
    opts = Keyword.merge(@default_table_options, opts)

    # Add column_order as a convenience for specifying column order by list
    opts =
      case Keyword.get(opts, :column_order) do
        nil ->
          opts

        columns when is_list(columns) ->
          # Create a sort function that orders columns based on their position in the list
          sort_fn = fn a, b ->
            a_index = Enum.find_index(columns, &(&1 == a)) || length(columns)
            b_index = Enum.find_index(columns, &(&1 == b)) || length(columns)
            a_index <= b_index
          end

          Keyword.put(opts, :sort_columns, sort_fn)

        other ->
          # If it's not a list, just pass it through as sort_columns
          Keyword.put(opts, :sort_columns, other)
      end

    # Add our width adjustment options
    opts =
      Keyword.merge(opts,
        max_width: max_width,
        max_column_widths: adjust_column_widths(column_preferences, max_width)
      )

    Owl.Table.new(data, opts)
  end
end
