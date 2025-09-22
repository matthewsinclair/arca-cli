defmodule Arca.Cli.Output do
  @moduledoc """
  Main output orchestration module for Arca.CLI.

  This module provides the central rendering pipeline that:
  - Determines the appropriate output style based on context and environment
  - Dispatches to the correct renderer (fancy, plain, or dump)
  - Handles the complete transformation from Context to final output string

  ## Style Precedence

  The output style is determined by the following precedence (highest to lowest):
  1. Explicit style in context metadata
  2. NO_COLOR environment variable (forces plain)
  3. ARCA_STYLE environment variable
  4. MIX_ENV=test (forces plain in test environment)
  5. TTY availability (fancy if TTY, plain otherwise)

  ## Available Styles

  - `:fancy` - Full colors, symbols, and enhanced formatting (TTY only)
  - `:plain` - No ANSI codes, plain text with Unicode symbols
  - `:dump` - Raw data dump for debugging, shows Context structure

  ## Examples

      iex> ctx = %Arca.Cli.Ctx{output: [{:success, "Done"}]}
      iex> Output.render(ctx)
      "✓ Done"

      iex> ctx = %Arca.Cli.Ctx{output: [{:error, "Failed"}], meta: %{style: :dump}}
      iex> Output.render(ctx)
      "%Arca.Cli.Ctx{...}"
  """

  alias Arca.Cli.Ctx
  alias Arca.Cli.Output.{FancyRenderer, PlainRenderer}
  require Logger

  @doc """
  Renders a Context to final output string.

  Takes a Context struct and renders it according to the determined style,
  returning a string ready for output.

  ## Parameters
    - ctx: The Context struct to render

  ## Returns
    - Formatted string output
  """
  @spec render(Ctx.t() | nil) :: String.t()
  def render(nil), do: ""

  def render(%Ctx{} = ctx) do
    ctx
    |> determine_style()
    |> apply_renderer(ctx)
    |> format_for_output()
  end

  # Style determination with precedence chain
  defp determine_style(%Ctx{meta: %{style: style}}) when style in [:fancy, :plain, :dump] do
    style
  end

  defp determine_style(%Ctx{} = ctx) do
    case check_environment() do
      {:style, style} -> style
      :auto -> auto_detect_style(ctx)
    end
  end

  # Check environment variables and settings
  defp check_environment do
    cond do
      no_color?() -> {:style, :plain}
      style = env_style() -> {:style, style}
      test_env?() -> {:style, :plain}
      true -> :auto
    end
  end

  # Auto-detect based on TTY availability
  defp auto_detect_style(_ctx) do
    case tty?() do
      true -> :fancy
      false -> :plain
    end
  end

  # Renderer dispatch
  defp apply_renderer(:fancy, ctx), do: FancyRenderer.render(ctx)
  defp apply_renderer(:plain, ctx), do: PlainRenderer.render(ctx) |> IO.iodata_to_binary()
  defp apply_renderer(:dump, ctx), do: dump_context(ctx)

  # Dump renderer for debugging
  defp dump_context(%Ctx{} = ctx) do
    %{
      command: ctx.command,
      args: ctx.args,
      options: ctx.options,
      output: ctx.output,
      errors: ctx.errors,
      status: ctx.status,
      cargo: ctx.cargo,
      meta: ctx.meta
    }
    |> inspect(pretty: true, width: 80, limit: :infinity)
  end

  # Final formatting - ensure we always return a string
  defp format_for_output(result) when is_binary(result), do: result
  defp format_for_output(result) when is_list(result), do: IO.iodata_to_binary(result)
  defp format_for_output(nil), do: ""
  defp format_for_output(result), do: to_string(result)

  # Environment detection helpers

  defp no_color? do
    case System.get_env("NO_COLOR") do
      nil -> false
      "" -> false
      "0" -> false
      "false" -> false
      _ -> true
    end
  end

  defp env_style do
    case System.get_env("ARCA_STYLE") do
      "fancy" -> :fancy
      "plain" -> :plain
      "dump" -> :dump
      _ -> nil
    end
  end

  defp test_env? do
    case System.get_env("MIX_ENV") do
      "test" -> true
      _ -> false
    end
  end

  defp tty? do
    # Check multiple indicators for TTY availability
    case {System.get_env("TERM"), IO.ANSI.enabled?()} do
      {nil, _} -> false
      {"dumb", _} -> false
      {_, false} -> false
      {_, true} -> true
    end
  end

  @doc """
  Returns the current output style that would be used for rendering.

  Useful for debugging and testing style determination logic.

  ## Parameters
    - ctx: Optional context to check for style metadata

  ## Returns
    - The style atom (:fancy, :plain, or :dump)

  ## Examples

      iex> Output.current_style()
      :fancy

      iex> ctx = %Ctx{meta: %{style: :plain}}
      iex> Output.current_style(ctx)
      :plain
  """
  @spec current_style(Ctx.t() | nil) :: :fancy | :plain | :dump
  def current_style(ctx \\ nil) do
    case ctx do
      nil -> determine_style(%Ctx{})
      %Ctx{} = context -> determine_style(context)
      _ -> determine_style(%Ctx{})
    end
  end
end