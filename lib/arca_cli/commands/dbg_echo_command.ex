defmodule Arca.Cli.Commands.DbgEchoCommand do
  @moduledoc """
  Debug command to echo back all parameters passed to it.
  Useful for debugging how parameters are parsed in different contexts.
  """
  use Arca.Cli.Command.BaseCommand

  config :"dbg.echo",
    name: "dbg.echo",
    about: "Debug utility: echo back all parameters passed to the command",
    hidden: true,
    allow_unknown_args: true,
    options: [
      option: [
        value_name: "OPTION",
        short: "-o",
        long: "--option",
        help: "Test option with value",
        parser: :string,
        required: false
      ]
    ],
    flags: [
      flag: [
        short: "-f",
        long: "--flag",
        help: "Test flag (boolean)"
      ]
    ],
    args: [
      text: [
        value_name: "TEXT",
        help: "Text argument which could contain spaces",
        required: false
      ],
      rest: [
        value_name: "REST",
        help: "Additional arguments",
        required: false,
        multiple: true
      ]
    ]

  @impl true
  def handle(args, _settings, _optimus) do
    """
    ....raw: #{inspect(args)}
    command: dbg.echo
    options: #{format_options(args)}
    ..flags: #{format_flags(args)}
    ...args: #{format_args(args)}
    unknown: #{format_unknown_args(args)}
    """
  end

  # Format the options section
  defp format_options(%{options: options}) when is_map(options) do
    options
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
    |> Enum.join(", ")
    |> case do
      "" -> "none"
      result -> result
    end
  end

  defp format_options(_), do: "none"

  # Format the flags section
  defp format_flags(%{flags: flags}) when is_map(flags) do
    flags
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
    |> Enum.join(", ")
    |> case do
      "" -> "none"
      result -> result
    end
  end

  defp format_flags(_), do: "none"

  # Format the args section
  defp format_args(%{args: args}) when is_map(args) do
    args
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
    |> Enum.join(", ")
    |> case do
      "" -> "none"
      result -> result
    end
  end

  defp format_args(_), do: "none"

  # Format unknown args section
  defp format_unknown_args(%{unknown: unknown}) when is_list(unknown) do
    case unknown do
      [] -> "none"
      _ -> inspect(unknown)
    end
  end

  defp format_unknown_args(_), do: "none"
end
