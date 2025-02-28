defmodule Arca.Cli.Commands.DbgTokensCommand do
  @moduledoc """
  Debug command to see how input is tokenized.
  """
  use Arca.Cli.Command.BaseCommand

  config :"dbg.tokens",
    name: "dbg.tokens",
    about: "Debug utility: shows how the input string is tokenized",
    hidden: true,
    allow_unknown_args: true

  @impl true
  def handle(args, _settings, _optimus) do
    # Get the raw command line that was passed to this command
    # We need to use optimus._commands to check which command was called
    # This assumes the last element in _commands is this command
    cmd_name = "dbg.tokens"
    cmd_len = String.length(cmd_name)

    # Use the Process dictionary to get the raw input from REPL
    raw_input = Process.get(:last_repl_input, "")

    cmd_input =
      if String.starts_with?(raw_input, cmd_name) do
        String.trim(String.slice(raw_input, cmd_len, String.length(raw_input) - cmd_len))
      else
        "unknown"
      end

    # Show raw tokens from the tokenizer
    tokens = get_raw_tokens(cmd_input)

    # Get tokens with quote processing
    processed_tokens = process_tokens(tokens)

    """
    .......raw: #{inspect(raw_input)}
    ...command: #{inspect(cmd_input)}
    raw tokens: #{inspect(tokens)}
    .processed: #{inspect(processed_tokens)}
    ......args: #{inspect(args)}
    """
  end

  # Get raw tokens from a string
  defp get_raw_tokens(input) do
    # Trim any leading/trailing whitespace
    trimmed = String.trim(input)

    # Regular expression to match:
    # 1. Quoted strings (preserving quotes)
    # 2. Option name=value with quoted value
    # 3. Non-whitespace sequences
    ~r/"[^"]*"|-{1,2}[^=]+=".+"|\S+/
    |> Regex.scan(trimmed)
    |> List.flatten()
  end

  # Process tokens to remove quotes where needed
  defp process_tokens(tokens) do
    tokens
    |> Enum.map(fn token ->
      cond do
        # Handle --option="value with spaces" format
        String.match?(token, ~r/^-{1,2}[^=]+=".+"$/) ->
          [name, value] = String.split(token, "=", parts: 2)
          # Remove quotes around the value
          unquoted_value = String.slice(value, 1, String.length(value) - 2)
          "#{name}=#{unquoted_value}"

        # Handle normal quoted strings
        String.starts_with?(token, "\"") && String.ends_with?(token, "\"") ->
          String.slice(token, 1, String.length(token) - 2)

        # Everything else passes through unchanged
        true ->
          token
      end
    end)
  end
end
