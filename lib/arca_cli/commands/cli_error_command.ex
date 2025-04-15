defmodule Arca.Cli.Commands.CliErrorCommand do
  @moduledoc """
  Command used for testing error handling scenarios.

  This command deliberately produces different types of errors
  to test the error handling pipeline.
  """
  use Arca.Cli.Command.BaseCommand

  config :"cli.error",
    name: "cli.error",
    about: "Test command for error handling",
    args: [
      error_type: [
        value_name: "TYPE",
        help: "Type of error to generate (raise, standard, legacy)",
        required: true
      ]
    ]

  @impl true
  def handle(args, _settings, _optimus) do
    case args.args.error_type do
      "raise" ->
        # Deliberately raise an exception
        raise "This is a test exception from CliErrorCommand"

      "standard" ->
        # Return a standard error tuple
        {:error, :invalid_argument, "This is a standard error tuple test"}

      "legacy" ->
        # Return a legacy error tuple
        {:error, "This is a legacy error tuple test"}

      "success" ->
        # Return success
        "Success: No error occurred"

      _ ->
        {:error, :invalid_argument,
         "Unknown error type. Use 'raise', 'standard', 'legacy', or 'success'."}
    end
  end
end
