defmodule PolymorphicFormatter do
  @moduledoc """
  Example formatter that demonstrates polymorphic callback handling.

  This formatter can handle both legacy string formatting and modern
  Context-based formatting, automatically detecting the input type
  and applying the appropriate transformation.
  """

  alias Arca.Cli.Ctx

  @doc """
  Format data based on its type - string or Context.

  ## Examples

      iex> PolymorphicFormatter.format("Hello")
      "[FORMATTED] Hello"

      iex> ctx = %Ctx{output: [{:text, "test"}]}
      iex> result = PolymorphicFormatter.format(ctx)
      iex> result.meta[:formatted_at] != nil
      true
  """
  def format(data)

  # Legacy string formatting
  def format(data) when is_binary(data) do
    "[FORMATTED] #{data}"
  end

  # Modern Context formatting
  def format(%Ctx{} = ctx) do
    ctx
    |> Ctx.set_meta(:formatted_at, DateTime.utc_now())
    |> Ctx.add_output({:info, "Formatted by callback"})
  end

  # Fallback for other types
  def format(other), do: other

  @doc """
  Add a timestamp to the output.
  Works with both strings and Contexts.
  """
  def add_timestamp(data)

  def add_timestamp(data) when is_binary(data) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    "#{data} [#{timestamp}]"
  end

  def add_timestamp(%Ctx{} = ctx) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    ctx
    |> Ctx.add_output({:info, "Generated at: #{timestamp}"})
  end

  def add_timestamp(other), do: other

  @doc """
  Add a summary to Context output.
  Only works with Context, passes strings through unchanged.
  """
  def add_summary(%Ctx{output: output} = ctx) when is_list(output) do
    count = length(output)

    ctx
    |> Ctx.add_output({:text, "---"})
    |> Ctx.add_output({:info, "Total output items: #{count}"})
  end

  def add_summary(other), do: other

  @doc """
  Filter output to only show certain types.
  Works only with Context.
  """
  def filter_errors_only(%Ctx{output: output} = ctx) when is_list(output) do
    errors_only =
      output
      |> Enum.filter(fn
        {:error, _} -> true
        _ -> false
      end)

    %{ctx | output: errors_only}
  end

  def filter_errors_only(other), do: other

  @doc """
  Chain multiple formatters together.

  ## Example

      iex> "test"
      ...> |> PolymorphicFormatter.format()
      ...> |> PolymorphicFormatter.add_timestamp()
      "[FORMATTED] test [2024-...]"
  """
  def chain_example(data) do
    data
    |> format()
    |> add_timestamp()
  end
end
