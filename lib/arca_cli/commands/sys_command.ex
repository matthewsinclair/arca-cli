defmodule Arca.CLI.Commands.SysCommand do
  @moduledoc """
  Arca CLI command to execute an OS command.
  """
  use Arca.CLI.Command.BaseCommand

  config :sys,
    name: "sys",
    about: "Run an OS command from within the CLI and return the results.",
    allow_unknown_args: true,
    args: [
      args: [
        value_name: "ARGS",
        help: "Arguments to OS command",
        required: false,
        parser: :string
      ]
    ]

  @doc """
  Run an OS command from within the CLI and return the results.

  ## Parameters

    - `oscmd`: The OS command to be executed.
    - `oscmd_args`: A list of arguments for the OS command.

  ## Returns

    - A tuple with the result of the command execution.
    - If the command is successful: `{res, 0}` where `res` is the command output.
    - If the command fails: `{error, reason}` where `error` is the error message and `reason` is the exit code.

  ## Examples

      iex> args = %{args: %{args: "pwd"}, unknown: []}
      ...> Arca.CLI.Command.OSCommand.handle(args, nil, nil)
      {"/home/user\n", 0}

      iex> args = %{args: %{args: "ls"}, unknown: ["-l"]}
      ...> Arca.CLI.Command.OSCommand.handle(args, nil, nil)
      {"total 0\n-rw-r--r--  1 user  group  0 Jan  1 00:00 file.txt\n", 0}

  """
  @impl Arca.CLI.Command.CommandBehaviour
  def handle(%{args: %{args: oscmd}, unknown: oscmd_args}, _settings, _optimus) do
    oscmd_args =
      case oscmd_args do
        [] -> []
        _ -> [Enum.join(oscmd_args, " ")]
      end

    try do
      case System.cmd(oscmd, oscmd_args) do
        {res, 0} ->
          res
          |> String.trim()
          |> Arca.CLI.Utils.print_ansi()

          {res, 0}

        {error, reason} ->
          reason
          |> inspect()
          |> String.trim()
          |> Arca.CLI.Utils.print_ansi()

          {error, reason}
      end
    rescue
      e in ErlangError ->
        case e.original do
          :enoent ->
            error_message = "Command not found: #{oscmd}"
            Arca.CLI.Utils.print_ansi(error_message)
            {error_message, :enoent}

          _ ->
            unknown_error = "An unknown error occurred: #{inspect(e)}"
            Arca.CLI.Utils.print_ansi(unknown_error)
            {unknown_error, :unknown}
        end
    end
  end
end
